const std = @import("std");
const gba = @import("gba.zig");
pub const window = @import("window.zig");
const Color = gba.Color;
const display = @This();
const Enable = gba.utils.Enable;
const U1_4 = gba.math.FixedPoint(.unsigned, 1, 4);

var current_page_addr: u32 = gba.mem.vram;

pub const vram: [*]volatile u16 = @ptrFromInt(gba.mem.vram);
pub const back_page: [*]volatile u16 = @ptrFromInt(gba.mem.vram + 0xA000);

/// Controls the capabilities of background layers
///
/// Modes 0-2 are tile modes, modes 3-5 are bitmap modes
pub const Mode = enum(u3) {
    /// Tiled mode
    ///
    /// Provides 4 normal background layers (0-3)
    mode0,
    /// Tiled mode
    ///
    /// Provides 2 normal (0, 1) and one affine (2) background layer
    mode1,
    /// Tiled mode
    ///
    /// Provides 2 affine (2, 3) background layers
    mode2,
    /// Bitmap mode
    ///
    /// Provides a 16bpp full screen bitmap frame
    mode3,
    /// Bitmap mode
    ///
    /// Provides two 8bpp (256 color palette) frames
    mode4,
    /// Bitmap mode
    ///
    /// Provides two 16bpp 160x128 pixel frames
    mode5,
};

pub const Flip = packed struct(u2) {
    h: bool = false,
    v: bool = false,
};

fn pageSize() u17 {
    return switch (ctrl.mode) {
        .mode3 => gba.bitmap.Mode3.page_size,
        .mode4 => gba.bitmap.Mode4.page_size,
        .mode5 => gba.bitmap.Mode5.page_size,
        else => 0,
    };
}

// TODO: This might make more sense elsewhere
pub fn currentPage() []volatile u16 {
    return @as([*]u16, @ptrFromInt(current_page_addr))[0..pageSize()];
}

// TODO: This might make more sense elsewhere
pub fn pageFlip() void {
    switch (ctrl.mode) {
        .mode4, .mode5 => {
            current_page_addr ^= 0xA000;
            ctrl.page_select ^= 1;
        },
        else => {},
    }
}

pub const ObjMapping = enum(u1) {
    /// Tiles are stored in rows of 32 * 64 bytes
    two_dimensions,
    /// Tiles are stored sequentially
    one_dimension,
};

pub const Priority = enum(u2) {
    highest,
    high,
    low,
    lowest,
};

pub const Control = packed struct(u16) {
    mode: Mode = .mode0,
    /// Read only, should stay false
    gbc_mode: bool = false,
    page_select: u1 = 0,
    oam_access_in_hblank: Enable = .disable,
    obj_mapping: ObjMapping = .two_dimensions,
    force_blank: bool = false,
    bg0: Enable = .disable,
    bg1: Enable = .disable,
    bg2: Enable = .disable,
    bg3: Enable = .disable,
    obj: Enable = .disable,
    window_0: Enable = .disable,
    window_1: Enable = .disable,
    window_obj: Enable = .disable,
};

/// Display Control Register
///
/// (`REG_DISPCNT`)
pub const ctrl: *volatile display.Control = @ptrFromInt(gba.mem.io);

pub const RefreshState = enum(u1) {
    draw,
    blank,
};

pub const Status = packed struct(u16) {
    /// Read only
    v_refresh: RefreshState,
    /// Read only
    h_refresh: RefreshState,
    /// Read only
    vcount_triggered: bool,
    vblank_irq: Enable = .disable,
    hblank_irq: Enable = .disable,
    vcount_trigger: Enable = .disable,
    _: u2 = 0,
    vcount_trigger_at: u8 = 0,
};

/// Display Status Register
///
/// (`REG_DISPSTAT`)
pub const status: *volatile display.Status = @ptrFromInt(gba.mem.io + 0x04);

/// Current y location of the LCD hardware
///
/// (`REG_VCOUNT`)
pub const vcount: *align(2) const volatile u8 = @ptrFromInt(gba.mem.io + 0x06);

// TODO: port the interrupt-based vsync
pub fn naiveVSync() void {
    while (vcount.* >= 160) {} // wait till VDraw
    while (vcount.* < 160) {} // wait till VBlank
}

/// Describes a mosaic effect
pub const Mosaic = packed struct(u16) {
    pub const Size = packed struct(u8) {
        x: u4 = 0,
        y: u4 = 0,
    };

    bg: Mosaic.Size = .{},
    sprite: Mosaic.Size = .{},
};

/// Controls size of mosaic effects for backgrounds and sprites where it is active
///
/// (`REG_MOSAIC`)
pub const mosaic: *volatile Mosaic = @ptrFromInt(gba.mem.io + 0x4C);

pub const Blend = packed struct {
    pub const Layers = packed struct(u6) {
        bg0: Enable = .disable,
        bg1: Enable = .disable,
        bg2: Enable = .disable,
        bg3: Enable = .disable,
        obj: Enable = .disable,
        backdrop: Enable = .disable,
    };

    pub const Mode = enum(u2) {
        none,
        blend,
        fade_white,
        fade_black,
    };

    a: Blend.Layers,
    mode: Blend.Mode,
    b: Blend.Layers,
    ev_a: U1_4,
    _0: u3,
    ev_b: U1_4,
    _1: u3,
    /// Write-only
    ev_fade: U1_4,
};

/// Controls for alpha blending
///
/// `ev_a`, `ev_b`, and `ev_fade` are 1.4 fixed point numbers, bounded by hardware at 0 and 1,
/// so any value with an integral bit of `1` is the same.
///
/// In other words, the fractional bits only matter if the integral bit is `0`.
///
/// (`REG_BLDMOD`, `BLD_EVA`, `BLD_EVB`, `BLD_EVY`)
pub const blend: *volatile Blend = @ptrFromInt(gba.mem.io + 0x50);

/// 4bpp/8bpp 8x8 tiles, "indexed" by letter coordinates (`tile.a.b`)
// TODO: if zig ever gets packed arrays, use them instead.
pub fn Tile(comptime mode: Color.Bpp) type {
    return packed struct {
        const Self = @This();

        pub const Block = [@divExact(0x4000, @sizeOf(Self))]Self;

        /// Color index type for this tile's palette
        pub const Pixel = switch (mode) {
            .bpp_4 => u4,
            .bpp_8 => u8,
        };

        /// Big-endian integer type for initializing a row in hexadecimal format.
        const IntRow = switch (mode) {
            .bpp_4 => u32,
            .bpp_8 => u64,
        };

        pub const Row = packed struct {
            a: Pixel,
            b: Pixel,
            c: Pixel,
            d: Pixel,
            e: Pixel,
            f: Pixel,
            g: Pixel,
            h: Pixel,
        };

        a: Row,
        b: Row,
        c: Row,
        d: Row,
        e: Row,
        f: Row,
        g: Row,
        h: Row,

        pub fn ram() *volatile [6]Block {
            return @ptrFromInt(gba.mem.vram);
        }

        /// Initialize with an 8x8 2D pixel array:
        ///
        /// ```
        /// // 4bpp
        /// Tile(.bpp_4).initInt(.{
        ///     .{ 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7 },
        ///     .{ 0x8, 0x9, 0xa, 0xb, 0xc, 0xd, 0xe, 0xf },
        ///     .{ 0x0, 0x1, 0x2, 0x3, 0x3, 0x2, 0x1, 0x0 },
        ///     .{ 0x0, 0xb, 0xa, 0xd, 0xf, 0x0, 0x0, 0xd },
        ///     .{ 0x9, 0x0, 0x0, 0xd, 0xf, 0xo, 0xo, 0xd },
        ///     .{ 0xd, 0xe, 0xa, 0xd, 0xb, 0xe, 0xe, 0xf },
        ///     .{ 0xc, 0xa, 0xf, 0xe, 0xb, 0xa, 0xb, 0xe },
        ///     .{ 0x1, 0x3, 0x3, 0x7, 0xc, 0x0, 0xd, 0xe },
        /// });
        ///
        /// // 8bpp
        /// Tile(.bpp_8).initInt(.{
        ///     .{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef },
        ///     .{ 0xfe, 0xdc, 0xba, 0x98, 0x76, 0x54, 0x32, 0x10 },
        ///     .{ 0x01, 0x23, 0x32, 0x10, 0x12, 0x34, 0x43, 0x21 },
        ///     .{ 0x90, 0x0d, 0xf0, 0x0d, 0x0b, 0xad, 0xf0, 0x0d },
        ///     .{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77 },
        ///     .{ 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff },
        ///     .{ 0xde, 0xad, 0xbe, 0xef, 0xca, 0xfe, 0xba, 0xbe },
        ///     .{ 0x69, 0x04, 0x20, 0x13, 0x37, 0xc0, 0xde, 0x69 },
        /// });
        /// ```
        pub fn init(comptime pixels: [8][8]Pixel) Self {
            return .{
                .a = comptime @bitCast(pixels[0]),
                .b = comptime @bitCast(pixels[1]),
                .c = comptime @bitCast(pixels[2]),
                .d = comptime @bitCast(pixels[3]),
                .e = comptime @bitCast(pixels[4]),
                .f = comptime @bitCast(pixels[5]),
                .g = comptime @bitCast(pixels[6]),
                .h = comptime @bitCast(pixels[7]),
            };
        }

        /// Initialize with 8 big-endian hexadecimal integers:
        ///
        /// ```
        /// // 4bpp
        /// Tile(.bpp_4).initInt(.{
        ///     0x01234567,
        ///     0x89abcdef,
        ///     0x01233210,
        ///     0x0badf00d,
        ///     0x900dfood,
        ///     0xdeadbeef,
        ///     0xcafebabe,
        ///     0x1337c0de,
        /// });
        ///
        /// // 8bpp
        /// Tile(.bpp_8).initInt(.{
        ///     0x01_23_45_67_89_ab_cd_ef,
        ///     0xfe_dc_ba_98_76_54_32_10,
        ///     0x01_23_32_10_12_34_43_21,
        ///     0x90_0d_f0_0d_0b_ad_f0_0d,
        ///     0x00_11_22_33_44_55_66_77,
        ///     0x88_99_aa_bb_cc_dd_ee_ff,
        ///     0xde_ad_be_ef_ca_fe_ba_be,
        ///     0x69_04_20_13_37_c0_de_69,
        /// });
        /// ```
        pub fn initInt(comptime rows: [8]IntRow) Self {
            return .{
                .a = comptime @bitCast(@byteSwap(rows[0])),
                .b = comptime @bitCast(@byteSwap(rows[1])),
                .c = comptime @bitCast(@byteSwap(rows[2])),
                .d = comptime @bitCast(@byteSwap(rows[3])),
                .e = comptime @bitCast(@byteSwap(rows[4])),
                .f = comptime @bitCast(@byteSwap(rows[5])),
                .g = comptime @bitCast(@byteSwap(rows[6])),
                .h = comptime @bitCast(@byteSwap(rows[7])),
            };
        }
    };
}

/// Copy memory into a charblock, containing tile data.
/// There are only 6 charblocks. The lower 4 are for background tiles
/// and the higher 2 are for sprites/objects.
/// Don't pass a block number higher than 5.
/// Note that screenblocks and charblocks share the same VRAM.
/// WARNING: This will not copy memory correctly if the input
/// data is not aligned on a 16-bit word boundary.
pub fn memcpyCharBlock(block: u3, data: []const u8) void {
    gba.mem.memcpy32(vram + (@as(u32, block) * 0x4000), @as([*]align(2) const u8, @ptrCast(@alignCast(data))), data.len);
}
