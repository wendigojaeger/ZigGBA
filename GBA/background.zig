const GBA = @import("core.zig").GBA;
const Display = @import("Display.zig");
const Priority = Display.Priority;
const Palette = @import("Palette.zig");
const PaletteMode = Palette.PaletteMode;
const Math = @import("Math.zig");
const I8_8 = Math.FixedI8_8;
const I20_8 = Math.FixedPoint(.signed, 20, 8);

pub const BG_PALETTE_ADDR = 0x05000000;

pub const bg_palette: []Palette.PaletteBank = @ptrFromInt(BG_PALETTE_ADDR);

/// Background size in tiles
pub const BackgroundSize = packed union { normal: enum(u2) {
    x32y32 = 0b00,
    x64y32 = 0b01,
    x32y64 = 0b10,
    x64y64 = 0b11,
}, affine: enum(u2) {
    x16y16 = 0b00,
    x32y32 = 0b01,
    x64y64 = 0b10,
    x128y128 = 0b11,
} };

pub const BackgroundControl = packed struct(u16) {
    priority: Priority = .Highest,
    /// Actual address = VRAM_BASE_ADDR + (tile_addr * 0x4000)
    tile_base_block: u2 = 0,
    _: u2 = undefined,
    mosaic: bool = false,
    palette_mode: PaletteMode = .Color16,
    /// Actual address = VRAM_BASE_ADDR + (obj_addr * 0x800)
    screen_base_block: u5 = 0,
    /// Whether affine backgrounds should wrap. Has no effect on normal backgrounds.
    affine_wrap: bool = false,
    /// Sizes differ depending on whether the background is affine.
    tile_map_size: BackgroundSize = .{ .normal = .x32y32 },
};

pub const Scroll = extern struct {
    x: i10 align(2) = 0,
    y: i10 align(2) = 0,

    pub inline fn set(self: *volatile Scroll, x: i10, y: i10) void {
        self.* = .{ .x = x, .y = y };
    }
};

pub const TextScreenEntry = packed struct {
    tile_idx: u10 = 0,
    flip_h: bool = false,
    flip_v: bool = false,
    palette_idx: u4 = 0,
};

// TODO: consider a generic affine?
pub const BgAffine = extern struct {
    pa: I8_8 align(2) = I8_8.fromInt(1),
    pb: I8_8 align(2) = .{},
    pc: I8_8 align(2) = .{},
    pd: I8_8 align(2) = I8_8.fromInt(1),
    dx: I20_8 align(4) = .{},
    dy: I20_8 align(4) = .{},
};

pub const AffineScreenEntry = packed struct {
    tile_idx: u8 = 0,
};

pub const TextScreenBlock = [1024]TextScreenEntry;
pub const ScreenBlockMemory: [*]align(4) volatile TextScreenBlock = @ptrFromInt(@intFromPtr(GBA.VRAM));

pub const Tile = extern struct { data: [8]u32 align(1) };

pub const CharacterBlock = [512]Tile;
pub const TileMemory: [*]align(4) volatile CharacterBlock = @ptrFromInt(@intFromPtr(GBA.VRAM));

pub const Tile8 = extern struct { data: [16]u32 align(1) };

pub const CharacterBlock8 = [256]Tile8;
pub const Tile8Memory: [*]align(4) volatile CharacterBlock8 = @ptrFromInt(@intFromPtr(GBA.VRAM));
