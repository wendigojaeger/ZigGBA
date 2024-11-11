//! Module for operations related to Object/Sprite memory
const gba = @import("gba.zig");
const I8_8 = gba.math.I8_8;
const display = gba.display;
const Priority = display.Priority;
const PaletteMode = gba.palette.Mode;
const Palette = gba.palette.Palette;

/// Tile data for objects
pub const tile_ram: [*]align(2) volatile u16 = @ptrFromInt(gba.mem.region.vram + 0x10000);

/// The actual location of objects in VRAM
pub const oam_data: *[128]Attribute = @ptrFromInt(gba.mem.region.oam);

/// A buffer that can be updated at any time, then copied
/// to OAM during VBlank
pub var obj_attr_buffer: [128]Attribute = @splat(.{});

/// Corresponding affine entries interleaved with the attribute buffer
///
/// Will be copied alongside objects
pub var affine_buffer: *[32]Affine align(4) = @ptrCast(&obj_attr_buffer);

var sort_keys: [128]u32 = @splat(0);

// TODO: Could make this ?u7 I think.
var sort_ids: [128]u8 = @splat(0);

pub fn shellSort(count: u8) void {
    var inc: u8 = 1;
    while (inc <= count) : (inc += 1)
        inc *= 3;
    while (true) {
        inc /= 3;
        for (inc..count) |i| {
            var j = i;
            const key_0 = sort_keys[sort_ids[i]];
            while (j >= inc and sort_keys[sort_ids[j - inc]] > key_0) : (j -= inc) {
                sort_ids[j] = sort_ids[j - inc];
            }
            sort_ids[j] = sort_ids[i];
        }
        if (inc <= 1) break;
    }
}

pub const palette: *Palette = @ptrFromInt(gba.mem.region.palette + 0x200);

var current_attr: usize = 0;

pub const GfxMode = enum(u2) {
    normal,
    alpha_blend,
    obj_window,
};

/// WIDTHxHEIGHT
pub const Size = enum {
    @"8x8",
    @"16x8",
    @"8x16",
    @"16x16",
    @"32x8",
    @"8x32",
    @"32x32",
    @"32x16",
    @"16x32",
    @"64x64",
    @"64x32",
    @"32x64",
};

const AffineMode = enum(u2) {
    /// Normal rendering, uses normal transform controls
    normal,
    /// Uses affine transform controls
    affine,
    /// Disables rendering
    hidden,
    /// Uses affine transform controls, and also allows affine
    /// transformations to use twice the sprite's dimensions.
    affine_double,
};

pub const Shape = enum(u2) {
    square,
    horizontal,
    vertical,
};

pub const Attribute = packed struct {
    /// Used to set transformation effects on an object
    const Transformation = packed union {
        normal: packed struct(u5) {
            _: u3 = 0,
            flip: display.Flip = .{},
        },
        affine_index: u5,
    };

    /// For normal sprites, the top; for affine sprites, the center
    y_pos: u8 = 0,
    affine_mode: AffineMode = .normal,
    mode: GfxMode = .normal,
    /// Enables mosaic effects on this object
    mosaic: bool = false,
    palette_mode: PaletteMode = .color_16,
    /// Used in combination with size, see `setSize`
    shape: Shape = .square,
    /// For normal sprites, the left side; for affine sprites, the center
    x_pos: u9 = 0,
    /// For normal sprites: whether to flip horizontally and/or vertically
    ///
    /// For affine sprites: the 5 bit index into the affine data
    transform: Transformation = .{ .normal = .{} },
    /// Used in combination with shape, see `setSize`
    size: u2 = 0,
    /// In bitmap modes, this must be 512 or higher
    tile_index: u10 = 0,
    priority: Priority = .highest,
    palette: u4 = 0,
    // This field is used to store the Affine data.
    // TODO: should maybe be undefined or left out?
    //_: I8_8 = ,

    /// Sets size and shape to the appropriate values for the given object size.
    pub fn setSize(self: *Attribute, size: Size) void {
        switch (size) {
            .@"8x8" => {
                self.shape = .square;
                self.size = 0;
            },
            .@"16x8" => {
                self.shape = .horizontal;
                self.size = 0;
            },
            .@"8x16" => {
                self.shape = .vertical;
                self.size = 0;
            },
            .@"16x16" => {
                self.shape = .square;
                self.size = 1;
            },
            .@"32x8" => {
                self.shape = .horizontal;
                self.size = 1;
            },
            .@"8x32" => {
                self.shape = .vertical;
                self.size = 1;
            },
            .@"32x32" => {
                self.shape = .square;
                self.size = 2;
            },
            .@"32x16" => {
                self.shape = .horizontal;
                self.size = 2;
            },
            .@"16x32" => {
                self.shape = .vertical;
                self.size = 2;
            },
            .@"64x64" => {
                self.shape = .square;
                self.size = 3;
            },
            .@"64x32" => {
                self.shape = .horizontal;
                self.size = 3;
            },
            .@"32x64" => {
                self.shape = .vertical;
                self.size = 3;
            },
        }
    }

    pub fn setPosition(self: *Attribute, x: u9, y: u8) void {
        self.x_pos = x;
        self.y_pos = y;
    }

    pub fn getAffine(self: Attribute) *Affine {
        return &affine_buffer[self.transform.affine_index];
    }
};

pub const Affine = packed struct {
    _0: u48,
    pa: I8_8 = I8_8.fromInt(1),
    _1: u48,
    pb: I8_8 = .{},
    _2: u48,
    pc: I8_8 = .{},
    _3: u48,
    pd: I8_8 = I8_8.fromInt(1),

    pub fn set(self: *Affine, pa: I8_8, pb: I8_8, pc: I8_8, pd: I8_8) void {
        self.pa = pa;
        self.pb = pb;
        self.pc = pc;
        self.pd = pd;
    }

    pub fn setIdentity(self: *Affine) void {
        self.pa = I8_8.fromInt(1);
        self.pb = .{};
        self.pc = .{};
        self.pd = I8_8.fromInt(1);
    }
};

// TODO: Better abstraction for this, maybe even using the allocator API
pub fn allocate() *Attribute {
    const result = &obj_attr_buffer[current_attr];
    current_attr += 1;
    return result;
}

/// Writes the object attribute buffer to OAM data.
///
/// Should only be done during VBlank
pub fn update(count: usize) void {
    for (obj_attr_buffer[0..count], oam_data[0..count]) |buf_entry, *oam_entry| {
        oam_entry.* = buf_entry;
    }
    current_attr = 0;
}
