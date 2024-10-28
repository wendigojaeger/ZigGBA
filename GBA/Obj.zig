//! Module for operations related to Object/Sprite memory

const I8_8 = @import("Math.zig").FixedI8_8;
const Priority = @import("Display.zig").Priority;

const OAM_BASE_ADDR = 0x07000000;
/// The actual location of object data in VRAM
const oam_data: *[128]Attribute = @ptrCast(OAM_BASE_ADDR);
/// A buffer that can be updated at any time, then copied
/// to OAM during VBlank
pub var obj_attr_buf: [128]Attribute = .{.{}} ** 128;
/// Corresponding affine entries interleaved with the attribute buffer
///
/// Will be copied alongside objects
pub var affine_buf: *[32]Affine align(4) = @ptrCast(&obj_attr_buf);

var current_attr: usize = 0;

pub const GfxMode = enum(u2) {
    Normal,
    SemiTransparent,
    ObjWindow,
};

/// Used to set transformation effects on an object
///
/// For normal sprites: whether to flip horizontally and/or vertically
///
/// For affine sprites: the 5 bit index into the affine data
pub const Transformation = packed union {
    normal: packed struct(u5) {
        _: u3 = 0,
        flip_h: bool = false,
        flip_v: bool = false,
    },
    affine_idx: u5,
};

pub const ObjectSize = enum {
    x8y8,
    x16y8,
    x8y16,
    x16y16,
    x32y8,
    x8y32,
    x32y32,
    x32y16,
    x16y32,
    x64y64,
    x64y32,
    x32y64,
};

const AffineMode = enum(u2) {
    /// Normal rendering, uses normal transform controls
    Normal,
    /// Uses affine transform controls
    Affine,
    /// Disables rendering
    Hidden,
    /// Uses affine transform controls, and also allows affine
    /// transformations to use twice the sprite's dimensions.
    AffineDouble,
};

pub const ObjectShape = enum(u2) {
    Square,
    Horizontal,
    Vertical,
};

pub const Attribute = packed struct {
    /// For normal sprites, the top; for affine sprites, the center
    y_pos: u8 = 0,
    affine_mode: AffineMode,
    mode: GfxMode = .Normal,
    /// Enables mosaic effects on this object
    mosaic: bool = false,
    palette_mode: @import(".zig").PaletteMode = .Color16,
    /// Used in combination with size, see setSize
    shape: ObjectShape = .Square,
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
    priority: Priority = 0,
    palette: u4 = 0,
    /// This field is used to store the Affine data.
    // TODO: should maybe be undefined or left out?
    _: I8_8 = I8_8.ZERO,

    const Self = @This();

    /// Sets size and shape to the appropriate values for the given
    /// object size.
    pub fn setSize(self: *Self, size: ObjectSize) void {
        switch (size) {
            .x8y8 => {
                self.shape = .Square;
                self.size = 0;
            },
            .x16y8 => {
                self.shape = .Horizontal;
                self.size = 0;
            },
            .x8y16 => {
                self.shape = .Vertical;
                self.size = 0;
            },
            .x16y16 => {
                self.shape = .Square;
                self.size = 1;
            },
            .x32y8 => {
                self.shape = .Horizontal;
                self.size = 1;
            },
            .x8y32 => {
                self.shape = .Vertical;
                self.size = 1;
            },
            .x32y32 => {
                self.shape = .Square;
                self.size = 2;
            },
            .x32y16 => {
                self.shape = .Horizontal;
                self.size = 2;
            },
            .x16y32 => {
                self.shape = .Vertical;
                self.size = 2;
            },
            .x64y64 => {
                self.shape = .Square;
                self.size = 3;
            },
            .x64y32 => {
                self.shape = .Horizontal;
                self.size = 3;
            },
            .x32y64 => {
                self.shape = .Vertical;
                self.size = 3;
            },
        }
    }

    pub inline fn setPosition(self: *Self, x: u9, y: u8) void {
        self.x_pos = x;
        self.y_pos = y;
    }

    pub fn getAffine(self: Self) *Affine {
        return &affine_buf[self.transform.affine_idx];
    }
};

pub const Affine = packed struct {
    _0: u48,
    pa: I8_8,
    _1: u48,
    pb: I8_8,
    _2: u48,
    pc: I8_8,
    _3: u48,
    pd: I8_8,

    fn set(self: *Affine, pa: I8_8, pb: I8_8, pc: I8_8, pd: I8_8) void {
        self.pa = pa;
        self.pb = pb;
        self.pc = pc;
        self.pd = pd;
    }

    fn setIdentity(self: *Affine) void {
        self.pa = I8_8.fromInt(1);
        self.pb = I8_8.ZERO;
        self.pc = I8_8.ZERO;
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
