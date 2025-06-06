const gba = @import("gba.zig");
const Color = gba.Color;
const display = gba.display;
const Enable = gba.utils.Enable;
const Priority = display.Priority;
const math = gba.math;
const I8_8 = math.I8_8;
const I20_8 = math.I20_8;
const Tile = display.Tile;

const bg = @This();

pub const palette: *Color.Palette = @ptrFromInt(gba.mem.palette);

/// Background size in 8x8 tiles
pub const Size = packed union {
    pub const Normal = enum(u2) {
        /// Uses one screenblock.
        @"32x32",
        /// Uses two screenblocks.
        @"64x32",
        /// Uses two screenblocks.
        @"32x64",
        /// Uses four screenblocks.
        @"64x64",
    };

    pub const Affine = enum(u2) {
        /// Uses 256 bytes of one screenblock.
        @"16x16",
        /// Uses 1024 bytes of one screenblock.
        @"32x32",
        /// Uses two screenblocks.
        @"64x64",
        /// Uses eight screenblocks.
        @"128x128",
    };

    normal: Size.Normal,
    affine: Size.Affine,
};

/// Represents the contents of REG_BGxCNT background control registers.
pub const Control = packed struct(u16) {
    /// Determines drawing order of the four backgrounds.
    priority: Priority = .highest,
    /// Sets the charblock that serves as the base for tile indexing.
    /// Only the first four of six charblocks may be used for backgrounds
    /// in this way.
    /// Actual address = VRAM_BASE_ADDR + (tile_addr * 0x4000)
    tile_base_block: u2 = 0,
    /// Unused bits.
    _: u2 = undefined,
    /// Enables mosaic effect. (Makes things appear blocky.)
    mosaic: Enable = .disable,
    /// Which format to expect charblock tile data to be in, whether
    /// 4bpp or 8bpp paletted.
    /// Affine backgrounds always use 8bpp.
    palette_mode: Color.Bpp = .bpp_4,
    /// The screenblock that serves as the base for screen-entry/map indexing.
    /// Beware that screenblock memory is shared with charblock memory.
    /// Screenblocks 0-7 occupy the same memory as charblock 0,
    /// screenblocks 8-15 as charblock 1,
    /// screenblocks 16-23 as charblock 2, and
    /// screenblocks 24-31 as charblock 3.
    /// Each screenblock holds 1024 (32x32) tiles.
    /// Actual address = VRAM_BASE_ADDR + (obj_addr * 0x800)
    screen_base_block: u5 = 0,
    /// Whether affine backgrounds should wrap.
    /// Has no effect on normal backgrounds.
    affine_wrap: Enable = .disable,
    /// Sizes differ depending on whether the background is affine.
    /// Larger sizes use more screenblocks.
    tile_map_size: Size = .{ .normal = .@"32x32" },
};

/// Background control registers for tile modes.
/// Corresponds to REG_BGxCNT.
///
/// Mode 0 - Normal: 0, 1, 2, 3
///
/// Mode 1 - Normal: 0, 1; Affine: 2
///
/// Mode 2 - Affine: 2, 3
pub const ctrl: *volatile [4]bg.Control = @ptrFromInt(gba.mem.io + 0x08);

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
pub const scroll: *[4]bg.Scroll = @ptrFromInt(gba.mem.io + 0x10);

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
pub const screen_block_ram: [*]volatile TextScreenBlock = @ptrCast(display.vram);

pub fn screenBlockMap(block: u5) [*]volatile bg.TextScreenEntry {
    return @ptrCast(&screen_block_ram[block]);
}

/// Copy memory into a screenblock, containing background layer data.
/// Note that screenblocks and charblocks share the same VRAM.
/// WARNING: This will not copy memory correctly if the input
/// data is not aligned on a 16-bit word boundary.
pub fn memcpyScreenBlock(block: u5, data: []const u8) void {
    gba.mem.memcpy32(display.vram + (@as(u32, block) * 0x800), @as([*]align(2) const u8, @ptrCast(@alignCast(data))), data.len);
}

pub const tile_ram = Tile(.bpp_4).ram();
pub const tile_8_ram = Tile(.bpp_8).ram();
