const GBA = @import("core.zig").GBA;
const IO = @import("IO.zig");
const Color = @import("color.zig").Color;

const VRAM_BASE_ADDR = 0x06000000;
const SPRITE_VRAM = VRAM_BASE_ADDR + 0x10000;
const MODE_4_PAGE_SIZE = 0xA000;
var current_page = VRAM_BASE_ADDR;

/// Controls the capabilities of background layers
///
/// Modes 0-2 are tile modes, modes 3-5 are bitmap modes
pub const DisplayMode = enum(u3) {
    /// Tiled mode
    ///
    /// Provides 4 normal background layers (0-3)
    Mode0,
    /// Tiled mode
    ///
    /// Provides 2 normal (0, 1) and one affine (2) background layer
    Mode1,
    /// Tiled mode
    ///
    /// Provides 2 affine (2, 3) background layers
    Mode2,
    /// Bitmap mode
    ///
    /// Provides a 16bpp full screen bitmap frame
    Mode3,
    /// Bitmap mode
    ///
    /// Provides two 8bpp (256 color palette) frames
    Mode4,
    /// Bitmap mode
    ///
    /// Provides two 16bpp 160x128 pixel frames (half size)
    Mode5,
};

pub const RefreshState = enum(u1) {
    Draw,
    Blank,
};

pub const DisplayStatus = packed struct(u16) {
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

pub const ObjCharacterMapping = enum(u1) {
    /// Tiles are stored in rows of 32 * 64 bytes
    TwoDimension,
    /// Tiles are stored sequentially
    OneDimension,
};

pub const Visiblity = enum(u1) {
    Hide,
    Show,
};

pub const Priority = enum(u2) {
    Highest,
    High,
    Low,
    Lowest,
};

pub const DisplayControl = packed struct {
    mode: DisplayMode = .Mode0,
    /// Read only, should stay false
    gbc_mode: bool = false,
    page_select: u1 = 0,
    oam_access_in_hblank: bool = false,
    obj_mapping: ObjCharacterMapping = .TwoDimension,
    force_blank: bool = false,
    bg0: Visiblity = .Hide,
    bg1: Visiblity = .Hide,
    bg2: Visiblity = .Hide,
    bg3: Visiblity = .Hide,
    obj_layer: Visiblity = .Hide,
    window0: Visiblity = .Hide,
    window1: Visiblity = .Hide,
    obj_window: Visiblity = .Hide,
};

pub const MosaicSize = packed struct(u8) {
    x: u4 = 0,
    y: u4 = 0,
};

pub const MosaicSettings = packed struct(u16) {
    bg: MosaicSize = .{ .x = 0, .y = 0 },
    sprite: MosaicSize = .{ .x = 0, .y = 0 },
};

pub inline fn currentPage() *volatile [MODE_4_PAGE_SIZE]u16 {
    // Could consider making the page a *[2][0xA000]PixelData
    // And just index in with display_ctrl.page_select
    // Probably too cheeky though
    return @ptrCast(current_page);
}

pub inline fn pageFlip() [*]volatile u16 {
    current_page ^= MODE_4_PAGE_SIZE;
    IO.display_ctrl.page_select = ~IO.display_ctrl.page_select;
    return currentPage();
}

pub inline fn naiveVSync() void {
    while (GBA.REG_VCOUNT.* >= 160) {} // wait till VDraw
    while (GBA.REG_VCOUNT.* < 160) {} // wait till VBlank
}
