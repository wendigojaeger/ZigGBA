const gba = @import("gba.zig");
const io = gba.io;

const VRAM_BASE_ADDR = 0x06000000;
const SPRITE_VRAM = VRAM_BASE_ADDR + 0x10000;
const MODE_4_PAGE_SIZE = 0xA000;
var current_page: u32 = VRAM_BASE_ADDR;

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
    /// Provides two 16bpp 160x128 pixel frames (half size)
    mode5,

    pub fn bitmap(mode: Mode) ?type {
        return switch (mode) {
            .mode3 => gba.Bitmap(gba.Color, 240, 160),
            .mode4 => gba.Bitmap(u8, 240, 160),
            .mode5 => gba.Bitmap(gba.Color, 120, 80),
            else => null,
        };
    }
};

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
    vcount_triggered: bool = false,
    enable_vblank_irq: bool = false,
    enable_hblank_irq: bool = false,
    enable_vcount_trigger: bool = false,
    _: u2 = 0,
    vcount_trigger_at: u8,
};

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

pub const Control = packed struct {
    const ShowLayers = packed struct(u8) {
        bg0: bool = false,
        bg1: bool = false,
        bg2: bool = false,
        bg3: bool = false,
        obj_layer: bool = false,
        window0: bool = false,
        window1: bool = false,
        obj_window: bool = false,
    };

    mode: Mode = .mode0,
    /// Read only, should stay false
    gbc_mode: bool = false,
    page_select: u1 = 0,
    oam_access_in_hblank: bool = false,
    obj_mapping: ObjMapping = .two_dimensions,
    force_blank: bool = false,
    show: ShowLayers = .{},
};

pub const MosaicSettings = packed struct(u16) {
    const Size = packed struct(u8) {
        x: u4 = 0,
        y: u4 = 0,
    };

    bg: Size = .{ .x = 0, .y = 0 },
    sprite: Size = .{ .x = 0, .y = 0 },
};

pub inline fn currentPage() *volatile [MODE_4_PAGE_SIZE]u16 {
    // Could consider making the page a *[2][0xA000]PixelData
    // And just index in with display_ctrl.page_select
    // Probably too cheeky though
    return @ptrFromInt(current_page);
}

pub inline fn pageFlip() [*]volatile u16 {
    current_page ^= MODE_4_PAGE_SIZE;
    io.display_ctrl.page_select = ~io.display_ctrl.page_select;
    return currentPage();
}

pub inline fn naiveVSync() void {
    while (io.reg_vcount.* >= 160) {} // wait till VDraw
    while (io.reg_vcount.* < 160) {} // wait till VBlank
}
