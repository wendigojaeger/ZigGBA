const std = @import("std");
const gba = @import("gba.zig");
const interrupt = @This();

pub const ctrl: *volatile interrupt.Control = @ptrFromInt(gba.mem.io + 0x200);

pub const Flag = enum {
    vblank,
    hblank,
    timer_0,
    timer_1,
    timer_2,
    timer_3,
    serial,
    dma_0,
    dma_1,
    dma_2,
    dma_3,
    keypad,
    gamepak,
};

pub const Flags = std.EnumSet(interrupt.Flag);

pub const WaitReturn = enum(u32) {
    return_immediately,
    discard_old_wait_new,
};

pub const Control = extern struct {
    /// When `master` is enabled, the events specified by these
    /// flags will trigger an interrupt.
    ///
    /// Since interrupts can trigger at any point, `master_enable`
    /// should be disabled while clearing flags from this register
    /// to avoid spurious interrupts.
    triggers: Flags align(2),
    /// Active interrupt requests can be read from this register.
    ///
    /// To clear an interrupt, write ONLY that flag to this register.
    /// the `acknowledge` method exists for this purpose.
    irq_ack: Flags align(2),
    /// Must be enabled for interrupts specified in `triggers` to activate.
    master: gba.Enable align(4),

    /// Acknowledges only the given interrupt, without ignoring others.
    pub fn acknowledge(self: *Control, flag: Flag) void {
        self.irq_ack = Flags.initOne(flag);
    }
};
