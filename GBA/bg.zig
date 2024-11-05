const gba = @import("gba.zig");
const display = gba.display;
const Priority = display.Priority;
const PaletteBank = gba.palette.Bank;
const math = gba.math;
const I8_8 = math.FixedI8_8;
const I20_8 = math.FixedPoint(.signed, 20, 8);

pub const PALETTE_ADDR = 0x05000000;

pub const palette: [*]PaletteBank = @ptrFromInt(PALETTE_ADDR);

/// Background size in tiles
pub const Size = packed union { normal: enum(u2) {
    @"32x32" = 0b00,
    @"64x32" = 0b01,
    @"32x64" = 0b10,
    @"64x64" = 0b11,
}, affine: enum(u2) {
    @"16x16" = 0b00,
    @"32x32" = 0b01,
    @"64x64" = 0b10,
    @"128x128" = 0b11,
} };

pub const Control = packed struct(u16) {
    priority: Priority = .highest,
    /// Actual address = VRAM_BASE_ADDR + (tile_addr * 0x4000)
    tile_base_block: u2 = 0,
    _: u2 = undefined,
    mosaic: bool = false,
    palette_mode: gba.palette.Mode = .color_16,
    /// Actual address = VRAM_BASE_ADDR + (obj_addr * 0x800)
    screen_base_block: u5 = 0,
    /// Whether affine backgrounds should wrap. Has no effect on normal backgrounds.
    affine_wrap: bool = false,
    /// Sizes differ depending on whether the background is affine.
    tile_map_size: Size = .{ .normal = .@"32x32" },
};

pub const Scroll = packed struct {
    x: i10 = 0,
    _: u6 = 0,
    y: i10 = 0,

    pub inline fn set(self: *volatile Scroll, x: i10, y: i10) void {
        self.* = .{ .x = x, .y = y };
    }
};

pub const TextScreenEntry = packed struct {
    tile_index: u10 = 0,
    flip_h: bool = false,
    flip_v: bool = false,
    palette_index: u4 = 0,
};

// TODO: consider a generic affine?
pub const Affine = extern struct {
    pa: I8_8 align(2) = I8_8.fromInt(1),
    pb: I8_8 align(2) = .{},
    pc: I8_8 align(2) = .{},
    pd: I8_8 align(2) = I8_8.fromInt(1),
    dx: I20_8 align(4) = .{},
    dy: I20_8 align(4) = .{},
};

pub const AffineScreenEntry = packed struct {
    tile_index: u8 = 0,
};

pub const TextScreenBlock = [1024]TextScreenEntry;
pub const screen_block_memory: [*]align(4) volatile TextScreenBlock = @ptrFromInt(@intFromPtr(gba.VRAM));

pub const Tile = extern struct { data: [8]u32 align(1) };

pub const CharacterBlock = [512]Tile;
pub const tile_memory: [*]align(4) volatile CharacterBlock = @ptrFromInt(@intFromPtr(gba.VRAM));

pub const Tile8 = extern struct { data: [16]u32 align(1) };

pub const CharacterBlock8 = [256]Tile8;
pub const tile_8_memory: [*]align(4) volatile CharacterBlock8 = @ptrFromInt(@intFromPtr(gba.VRAM));
