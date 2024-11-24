const gba = @import("gba.zig");
pub const window = @import("window.zig");
const Color = gba.Color;
const display = @This();
const Enable = gba.Enable;
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
/// `eva`, `evb`, and `evy` are 1.4 fixed point numbers, bounded by hardware at 0 and 1,
/// so any value with an integral bit of `1` is the same.
///
/// In other words, the fractional bits only matter if the integral bit is `0`.
///
/// (`REG_BLDMOD`, `REG_)
pub const blend: *volatile Blend = @ptrFromInt(gba.mem.io + 0x50);

/// 4bpp/8bpp 8x8 tiles, "indexed" by letter coordinates (`tile.a.b`)
// TODO: if zig ever gets packed arrays, use them instead.
pub fn Tile(comptime mode: Color.Mode) type {
    return packed struct {
        const Self = @This();

        pub const Block = [@divExact(0x4000, @sizeOf(Self))]Self;

        /// Color index for this tile's palette
        pub const Pixel = switch (mode) {
            .color_16 => u4,
            .color_256 => u8,
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
    };
}
