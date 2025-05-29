const std = @import("std");
const gba = @import("gba.zig");
const Enable = gba.utils.Enable;
const timer = @This();

/// Enumeration of recognized timer tick frequencies.
pub const Frequency = enum(u2) {
    /// One timer tick per clock cycle.
    /// Equivalent to 1/16777216th second, or approximately 0.06 nanoseconds.
    cycles_1 = 0,
    /// One timer tick per 64 clock cycles.
    /// Equivalent to 1/262144th second, or approximately 3.8 nanoseconds.
    cycles_64 = 1,
    /// One timer tick per 256 clock cycles.
    /// Equivalent to 1/65536th second, or approximately 15 nanoseconds.
    cycles_256 = 2,
    /// One timer tick per 1024 clock cycles.
    /// Equivalent to 1/16384th second, or approximately 61 nanoseconds.
    cycles_1024 = 3,
};

/// Represents the data of a REG_TMxCNT timer control register.
pub const Control = packed struct(u16) {
    /// Timer frequency.
    /// One second is equivalent to 1024 * 0x4000 clock cycles.
    freq: Frequency = .cycles_1,
    /// Cascade mode. When this bit is set, this timer will be incremented
    /// when the previous timer overflows. (The timer must also be enabled.)
    cascade: Enable = .disable,
    /// Unused bits.
    unused_1: u3 = 0,
    /// Raise an interrupt upon overflow.
    interrupt: Enable = .disable,
    /// Enable the timer.
    enable: Enable = .disable,
    /// Unused bits.
    unused_2: u8 = 0,
};

/// Corresponds to tonc REG_TM1D.
/// Writing to this register does NOT set the current timer value.
/// It sets the INITIAL timer value for the next timer run.
pub const data_1: *volatile u16 = @ptrFromInt(gba.mem.io + 0x100);

/// Corresponds to tonc REG_TM1CNT.
pub const ctrl_1: *volatile timer.Control = @ptrFromInt(gba.mem.io + 0x102);

/// Corresponds to tonc REG_TM2D.
/// Writing to this register does NOT set the current timer value.
/// It sets the INITIAL timer value for the next timer run.
pub const data_2: *volatile u16 = @ptrFromInt(gba.mem.io + 0x104);

/// Corresponds to tonc REG_TM2CNT.
pub const ctrl_2: *volatile timer.Control = @ptrFromInt(gba.mem.io + 0x106);

/// Corresponds to tonc REG_TM3D.
/// Writing to this register does NOT set the current timer value.
/// It sets the INITIAL timer value for the next timer run.
pub const data_3: *volatile u16 = @ptrFromInt(gba.mem.io + 0x108);

/// Corresponds to tonc REG_TM3CNT.
pub const ctrl_3: *volatile timer.Control = @ptrFromInt(gba.mem.io + 0x10a);

/// Corresponds to tonc REG_TM4D.
/// Writing to this register does NOT set the current timer value.
/// It sets the INITIAL timer value for the next timer run.
pub const data_4: *volatile u16 = @ptrFromInt(gba.mem.io + 0x10c);

/// Corresponds to tonc REG_TM4CNT.
pub const ctrl_4: *volatile timer.Control = @ptrFromInt(gba.mem.io + 0x10e);
