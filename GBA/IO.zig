//! Access to MMIO registers

const Display = @import("Display.zig");
const DisplayMode = Display.DisplayMode;
const DisplayStatus = Display.DisplayStatus;
const MosaicSettings = Display.MosaicSettings;
const Bg = @import("background.zig");
const GBA = @import("core.zig").GBA;
const Interrupt = GBA.Interrupt;
const InterruptFlags = GBA.InterruptFlags;

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
/// Background control registers for tile modes
/// 
/// Mode 0 - Normal: 0, 1, 2, 3
/// 
/// Mode 1 - Normal: 0, 1; Affine: 2
/// 
/// Mode 2 - Affine: 2, 3
pub const bg_ctrl: *volatile [4]Bg.BackgroundControl = @ptrFromInt(IO_BASE_ADDR + 0x08);
/// Controls background scroll. Values are modulo map size (wrapping is automatic)
/// 
/// These registers are write only.
pub const bg_scroll: *volatile [4]Bg.Scroll = @ptrFromInt(IO_BASE_ADDR + 0x10);

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

pub const InterruptCtrl = extern struct {
    /// When `master_enable` is true, the events specified by these
    /// flags will trigger an interrupt.
    /// 
    /// Since interrupts can trigger at any point, `master_enable` 
    /// should be disabled while clearing flags from this register
    /// to avoid spurious interrupts.
    enable: InterruptFlags align(2),
    /// Interrupt requests can be read from this register.
    /// 
    /// To clear an interrupt, write ONLY that flag to this register.
    /// the `acknowledge` method exists for this purpose.
    irq_ack: InterruptFlags align(2),
    /// Must be true for interrupts specified in `enable` to trigger.
    master_enable: bool,

    /// Acknowledges only the given interrupt, without ignoring others.
    fn acknowledge(self: *InterruptCtrl, flag: Interrupt) void {
        self.irq_ack = InterruptFlags.initOne(flag);
    }
};

pub const interrupt_ctrl: *volatile InterruptCtrl = @ptrCast(IO_BASE_ADDR + 0x200);
