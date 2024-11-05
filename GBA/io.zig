//! Access to MMIO registers

const gba = @import("gba.zig");
const display = gba.display;
const bg = gba.bg;
const Interrupt = gba.Interrupt;

const IO_BASE_ADDR = 0x4000000;

pub const Input = @import("Input.zig");

/// Display Control Register
///
/// (REG_DISPCNT)
pub const display_ctrl: *volatile display.Control = @ptrFromInt(IO_BASE_ADDR);
/// Display Status Register
///
/// (REG_DISPSTAT)
pub const display_status: *volatile display.Status = @ptrFromInt(IO_BASE_ADDR + 0x04);
/// Current y location of the LCD hardware
///
/// (REG_VCOUNT)
pub const reg_vcount: *align(2) const volatile u8 = @ptrFromInt(IO_BASE_ADDR + 0x06);
/// Background control registers for tile modes
///
/// Mode 0 - Normal: 0, 1, 2, 3
///
/// Mode 1 - Normal: 0, 1; Affine: 2
///
/// Mode 2 - Affine: 2, 3
pub const bg_ctrl: *volatile [4]bg.Control = @ptrFromInt(IO_BASE_ADDR + 0x08);
/// Controls background scroll. Values are modulo map size (wrapping is automatic)
///
/// These registers are write only.
pub const bg_scroll: *volatile [4]bg.Scroll = @ptrFromInt(IO_BASE_ADDR + 0x10);

/// Controls size of mosaic effects for backgrounds and sprites where it is active
///
/// (REG_MOSAIC)
pub const mosaic_size: *volatile display.MosaicSettings = @ptrCast(IO_BASE_ADDR + 0x4C);

pub const BlendFlags = packed struct(u6) {
    bg0: bool,
    bg1: bool,
    bg2: bool,
    bg3: bool,
    sprites: bool,
    backdrop: bool,
};

pub const BlendMode = enum(u2) {
    None,
    AlphaBlend,
    FadeWhite,
    FadeBlack,
};

pub const BlendSettings = packed struct(u16) {
    source: BlendFlags,
    mode: BlendMode,
    target: BlendFlags,
};

/// Controls blend mode and which layers are blended
///
/// (REG_BLDMOD)
pub const blend_settings: *volatile BlendSettings = @ptrCast(IO_BASE_ADDR + 0x50);

pub const interrupt_ctrl: *volatile Interrupt.Control = @ptrCast(IO_BASE_ADDR + 0x200);
