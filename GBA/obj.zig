//! Module for operations related to Object/Sprite memory
const std = @import("std");
const gba = @import("gba.zig");
const Color = gba.Color;
const Enable = gba.utils.Enable;
const I8_8 = gba.math.I8_8;
const display = gba.display;
const Priority = display.Priority;
const Tile = display.Tile;

/// Tile data for objects
pub const tile_ram: *volatile [2][512]Tile(.bpp_4) = @ptrFromInt(gba.mem.vram + 0x10000);

/// Obj and `Affine` data is interleaved but starts at the same place in memory.
const ObjAffineData = packed union {
    obj: *[128]Obj align(4),
    affine: *[32]Affine align(4),
};

/// The actual location of objects in VRAM
///
/// Should only be updated during VBlank, to avoid graphical glitches.
pub const oam: ObjAffineData = .{ .obj = @ptrFromInt(gba.mem.oam) };

var buffer_inner: [128]Obj align(8) = @splat(.{});

/// A buffer that can be updated at any time, then copied
/// to OAM during VBlank
pub var obj_affine_buffer: ObjAffineData = .{ .obj = &buffer_inner };

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

pub const Obj = packed struct {
    pub const GfxMode = enum(u2) {
        normal,
        alpha_blend,
        obj_window,
    };

    pub const Shape = enum(u2) {
        square,
        wide,
        tall,
    };

    /// WIDTHxHEIGHT
    pub const Size = enum(u4) {
        // Square
        @"8x8",
        @"16x16",
        @"32x32",
        @"64x64",
        // Wide
        @"16x8",
        @"32x8",
        @"32x16",
        @"64x32",
        // Tall
        @"8x16",
        @"8x32",
        @"16x32",
        @"32x64",

        const Parts = packed struct(u4) {
            size: u2,
            shape: Shape,
        };

        fn parts(self: Size) Parts {
            return @bitCast(@intFromEnum(self));
        }
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

    /// Used to set transformation effects on an object
    const Transformation = packed union {
        flip: packed struct(u5) {
            _: u3 = 0,
            h: bool = false,
            v: bool = false,
        },
        affine_index: u5,
    };

    /// Many docs treat this as a single 10 bit number, but the most significant bit
    /// corresponds to which of the last two charblocks the index is into.
    ///
    /// It can still be assigned to with a u10 via `@bitCast`
    pub const TileInfo = packed struct(u10) {
        /// The index into tile memory in VRAM. Indexing is always based on 4bpp tiles
        ///
        /// (for 8bpp tiles, only even indices are used, so `logical_index << 1` works)
        index: u9 = 0,
        /// Selects between the low and high block of obj VRAM
        ///
        /// In bitmap modes, this must be 1, since the lower block is occupied by the bitmap.
        block: u1 = 0,
    };

    /// For normal sprites, the top; for affine sprites, the center
    y_pos: u8 = 0,
    affine_mode: AffineMode = .normal,
    mode: GfxMode = .normal,
    /// Enables mosaic effects on this object
    mosaic: Enable = .disable,
    palette_mode: Color.Bpp = .bpp_4,
    /// Used in combination with size, see `setSize`
    shape: Shape = .square,
    /// For normal sprites, the left side; for affine sprites, the center
    x_pos: u9 = 0,
    /// For normal sprites: whether to flip horizontally and/or vertically
    ///
    /// For affine sprites: the 5 bit index into the affine data
    transform: Transformation = .{ .flip = .{} },
    /// Used in combination with shape, see `setSize`
    size: u2 = 0,
    tile: TileInfo = .{},
    priority: Priority = .highest,
    palette: u4 = 0,
    // This field is used to store the Affine data.
    // TODO: should maybe be undefined or left out?
    // _: I8_8 = undefined,

    /// Sets size and shape to the appropriate values for the given object size.
    pub fn setSize(self: *Obj, size: Size) void {
        const parts = size.parts();
        self.size = parts.size;
        self.shape = parts.shape;
    }

    pub fn setPosition(self: *Obj, x: u9, y: u8) void {
        self.x_pos = x;
        self.y_pos = y;
    }

    pub fn getAffine(self: Obj) *Affine {
        return &obj_affine_buffer.affine[self.transform.affine_index];
    }

    pub fn flipH(self: *Obj) void {
        switch (self.affine_mode) {
            .normal => self.transform.flip.h = !self.transform.flip.h,
            // TODO: implement affine flips
            .affine, .affine_double => {},
            else => {},
        }
    }

    pub fn flipV(self: *Obj) void {
        switch (self.affine_mode) {
            .normal => self.transform.flip.v = !self.transform.flip.v,
            // TODO: implement affine flips
            .affine, .affine_double => {},
            else => {},
        }
    }

    pub fn rotate180(self: *Obj) void {
        switch (self.affine_mode) {
            .normal => self.transform.flip = .{
                .h = !self.transform.flip.h,
                .v = !self.transform.flip.v,
            },
            // TODO: implement affine flips
            .affine, .affine_double => {},
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
pub fn allocate() *Obj {
    const result = &obj_affine_buffer.obj[current_attr];
    current_attr += 1;
    return result;
}

/// Writes the object attribute buffer to OAM data.
///
/// Should only be done during VBlank
pub fn update(count: usize) void {
    for (obj_affine_buffer.obj[0..count], oam.obj[0..count]) |buf_entry, *oam_entry| {
        oam_entry.* = buf_entry;
    }
    current_attr = 0;
}
