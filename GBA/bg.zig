const gba = @import("gba.zig");
const display = gba.display;
const Priority = display.Priority;
const Palette = gba.palette.Palette;
const math = gba.math;
const I8_8 = math.I8_8;
const I20_8 = math.I20_8;

const bg = @This();

pub const palette: *Palette = @ptrFromInt(gba.mem.region.palette);

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

/// Background control registers for tile modes
///
/// Mode 0 - Normal: 0, 1, 2, 3
///
/// Mode 1 - Normal: 0, 1; Affine: 2
///
/// Mode 2 - Affine: 2, 3
pub const ctrl: *volatile [4]bg.Control = @ptrFromInt(gba.mem.region.io + 0x08);

/// Only the lowest 10 bits are used
pub const Scroll = packed struct {
    x: i16 = 0,
    y: i16 = 0,

    pub fn set(self: *volatile Scroll, x: i10, y: i10) void {
        self.* = .{ .x = x, .y = y };
    }
};

/// Controls background scroll. Values are modulo map size (wrapping is automatic)
///
/// These registers are write only.
pub const scroll: *[4]bg.Scroll = @ptrFromInt(gba.mem.region.io + 0x10);

pub const TextScreenEntry = packed struct(u16) {
    tile_index: u10 = 0,
    flip: display.Flip = .{},
    palette_index: u4 = 0,
};

// TODO: consider a generic affine matrix type with functions for identity and other common transformations?
pub const Affine = extern struct {
    pa: I8_8 align(2) = I8_8.fromInt(1),
    pb: I8_8 align(2) = .{},
    pc: I8_8 align(2) = .{},
    pd: I8_8 align(2) = I8_8.fromInt(1),
    dx: I20_8 align(4) = .{},
    dy: I20_8 align(4) = .{},
};

/// An index to a color tile
pub const AffineScreenEntry = u8;

pub const TextScreenBlock = [1024]TextScreenEntry;
pub const screen_block_memory: [*]volatile TextScreenBlock = @ptrCast(display.vram);

pub const Tile = extern struct { data: [8]u32 align(1) };

pub const CharacterBlock = [512]Tile;
pub const tile_memory: [*]volatile CharacterBlock = @ptrCast(display.vram);

pub const Tile8 = extern struct { data: [16]u32 align(1) };

pub const CharacterBlock8 = [256]Tile8;
pub const tile_8_memory: [*]volatile CharacterBlock8 = @ptrCast(display.vram);
