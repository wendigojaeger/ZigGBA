//! Module for operations related to Object/Sprite memory
const gba = @import("gba.zig");
const I8_8 = gba.math.FixedI8_8;
const Priority = gba.display.Priority;
const palette = gba.palette;

const OAM_BASE_ADDR = 0x07000000;
/// The actual location of object data in VRAM
pub const oam_data: *[128]Attribute = @ptrFromInt(OAM_BASE_ADDR);
/// A buffer that can be updated at any time, then copied
/// to OAM during VBlank
pub var obj_attr_buf: [128]Attribute = .{.{}} ** 128;
/// Corresponding affine entries interleaved with the attribute buffer
///
/// Will be copied alongside objects
pub var affine_buf: *[32]Affine align(4) = @ptrCast(&obj_attr_buf);

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
            flip_h: bool = false,
            flip_v: bool = false,
        },
        affine_idx: u5,
    };


    /// For normal sprites, the top; for affine sprites, the center
    y_pos: u8 = 0,
    affine_mode: AffineMode = .normal,
    mode: GfxMode = .normal,
    /// Enables mosaic effects on this object
    mosaic: bool = false,
    palette_mode: palette.Mode = .color_16,
    /// Used in combination with size, see setSize
    shape: Shape = .square,
    /// For normal sprites, the left side; for affine sprites, the center
    x_pos: u9 = 0,
    /// For normal sprites: whether to flip horizontally and/or vertically
    ///
    /// For affine sprites: the 5 bit index into the affine data
    transform: Transformation = .{ .normal = .{} },
    /// Used in combination with shape, see setSize
    size: u2 = 0,
    /// In bitmap modes, this must be 512 or higher
    tile_idx: u10 = 0,
    priority: Priority = .highest,
    palette: u4 = 0,
    // This field is used to store the Affine data.
    // TODO: should maybe be undefined or left out?
    //_: I8_8 = ,

    /// Sets size and shape to the appropriate values for the given
    /// object size.
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

    pub inline fn setPosition(self: *Attribute, x: u9, y: u8) void {
        self.x_pos = x;
        self.y_pos = y;
    }

    pub fn getAffine(self: Attribute) *Affine {
        return &affine_buf[self.transform.affine_idx];
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

pub fn allocate() *Attribute {
    const result = &obj_attr_buf[current_attr];
    current_attr += 1;
    return result;
}

pub fn update(count: usize) void {
    for (obj_attr_buf[0..count], oam_data[0..count]) |buf_entry, *oam_entry| {
        oam_entry.* = buf_entry;
    }
    current_attr = 0;
}
