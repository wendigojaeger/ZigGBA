//! Access to MMIO registers

const Display = @import("lcd.zig");
const DisplayMode = Display.DisplayMode;
const DisplayStatus = Display.DisplayStatus;
const MosaicSettings = Display.MosaicSettings;
const BackgroundLayer = Display.BackgroundLayer;

const IO_BASE_ADDR = 0x4000000;

pub const Input = @import("Input.zig");

/// Display Control Register
/// 
/// (REG_DISPCNT)
pub const display_ctrl: *volatile Display.DisplayControl = @ptrFromInt(IO_BASE_ADDR);
/// Display Status Register
/// 
/// (REG_DISPSTAT)
pub const display_status: *volatile DisplayStatus = @ptrFromInt(IO_BASE_ADDR + 0x04);
/// Current y location of the LCD hardware
/// 
/// (REG_VCOUNT)
pub const reg_vcount: *align(2) volatile const u8 = @ptrFromInt(IO_BASE_ADDR + 0x06);

/// Background Registers
/// 
/// bg_layers[x] Contains pointers to REG_BGxCNT, REG_BGxHOFS, and REG_BGxVOFS
pub const bg_layers: []BackgroundLayer = &[_]BackgroundLayer{
    .{
        .control = @ptrCast(IO_BASE_ADDR + 0x08),
        .h_offset = @ptrCast(IO_BASE_ADDR + 0x10),
        .v_offset = @ptrCast(IO_BASE_ADDR + 0x12),
    },
    .{
        .control = @ptrCast(IO_BASE_ADDR + 0x0A),
        .h_offset = @ptrCast(IO_BASE_ADDR + 0x14),
        .v_offset = @ptrCast(IO_BASE_ADDR + 0x16),
    },
    .{
        .control = @ptrCast(IO_BASE_ADDR + 0x0C),
        .h_offset = @ptrCast(IO_BASE_ADDR + 0x18),
        .v_offset = @ptrCast(IO_BASE_ADDR + 0x1A),
    },
    .{
        .control = @ptrCast(IO_BASE_ADDR + 0x0E),
        .h_offset = @ptrCast(IO_BASE_ADDR + 0x1C),
        .v_offset = @ptrCast(IO_BASE_ADDR + 0x1E),
    },
};

/// Controls size of mosaic effects for backgrounds and sprites where it is active
/// 
/// (REG_MOSAIC)
pub const mosaic_size: *volatile MosaicSettings = @ptrCast(IO_BASE_ADDR + 0x4C);

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
pub const blend_settings: *volatile BlendSettings =  @ptrCast(IO_BASE_ADDR + 0x50);
