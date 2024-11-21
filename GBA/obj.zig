//! Module for operations related to Object/Sprite memory
const gba = @import("gba.zig");
const Color = gba.Color;
const Enable = gba.Enable;
const I8_8 = gba.math.I8_8;
const display = gba.display;
const Priority = display.Priority;

/// Tile data for objects
pub const tile_ram: [*]align(2) volatile u16 = @ptrFromInt(gba.mem.vram + 0x10000);

/// The actual location of objects in VRAM
pub const obj_attributes: *[128]Attributes = @ptrFromInt(gba.mem.oam);

/// A buffer that can be updated at any time, then copied
/// to OAM during VBlank
pub var obj_attr_buffer: [128]Attributes = @splat(.{});

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

pub const palette: *Color.Palette = @ptrFromInt(gba.mem.palette + 0x200);

var current_attr: usize = 0;

pub const Attributes = packed struct {
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
        /// Normal rendering, uses `normal` transform controls
        normal,
        /// Uses `affine` transform controls
        affine,
        /// Disables rendering
        hidden,
        /// Uses `affine` transform controls, and also allows affine
        /// transformations to use twice the sprite's dimensions.
        affine_double,
    };

    pub const Shape = enum(u2) {
        square,
        horizontal,
        vertical,
    };

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
    mosaic: Enable = .disable,
    palette_mode: Color.Mode = .color_16,
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
    pub fn setSize(self: *Attributes, size: Size) void {
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

    pub fn setPosition(self: *Attributes, x: u9, y: u8) void {
        self.x_pos = x;
        self.y_pos = y;
    }

    pub fn getAffine(self: Attributes) *Affine {
        return &affine_buffer[self.transform.affine_index];
    }

    pub fn flipH(self: *Attributes) void {
        switch (self.affine_mode) {
            .normal => self.transform.normal.flip.h = !self.transform.normal.flip.h,
            .affine, .affine_double => {}, // TODO: implement affine flips"
            else => {},
        }
    }

    pub fn flipV(self: *Attributes) void {
        switch (self.affine_mode) {
            .normal => self.transform.normal.flip.v = !self.transform.normal.flip.v,
            .affine, .affine_double => {}, // TODO: implement affine flips"
            else => {},
        }
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
        self.set(I8_8.fromInt(1), .{}, .{}, I8_8.fromInt(1));
    }
};

// TODO: Better abstraction for this, maybe even using the `std.Allocator` API
pub fn allocate() *Attributes {
    const result = &obj_attr_buffer[current_attr];
    current_attr += 1;
    return result;
}

/// Writes the object attribute buffer to OAM data.
///
/// Should only be done during VBlank
pub fn update(count: usize) void {
    for (obj_attr_buffer[0..count], obj_attributes[0..count]) |buf_entry, *oam_entry| {
        oam_entry.* = buf_entry;
    }
    current_attr = 0;
}
