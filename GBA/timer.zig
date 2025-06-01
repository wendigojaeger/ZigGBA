const std = @import("std");
const gba = @import("gba.zig");
const Enable = gba.utils.Enable;

/// Encapsulates access to REG_TMxD and REG_TMxCNT registers
/// for controlling and reading one of the GBA's four timers.
pub const Timer = packed struct(u32) {
    /// Enumeration of recognized timer tick frequencies.
    pub const Frequency = enum(u2) {
        /// One timer tick per clock cycle.
        /// Equivalent to 1/16777216th second, or approximately 0.06 microseconds.
        cycles_1 = 0,
        /// One timer tick per 64 clock cycles.
        /// Equivalent to 1/262144th second, or approximately 3.8 microseconds.
        cycles_64 = 1,
        /// One timer tick per 256 clock cycles.
        /// Equivalent to 1/65536th second, or approximately 15 microseconds.
        cycles_256 = 2,
        /// One timer tick per 1024 clock cycles.
        /// Equivalent to 1/16384th second, or approximately 61 microseconds.
        cycles_1024 = 3,
    };

    /// Represents the data of a REG_TMxCNT timer control register.
    pub const Control = packed struct(u16) {
        /// Timer frequency.
        /// One second is equivalent to 1024 * 0x4000 clock cycles.
        freq: Timer.Frequency = .cycles_1,
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
    
    /// Corresponds to tonc REG_TMxD.
    /// Reading this register gives a timer's current elapsed intervals.
    /// Writing to this register does NOT set the current timer value.
    /// It sets the INITIAL timer value for the next timer run.
    data: u16,
    
    /// Corresponds to tonc REG_TMxCNT.
    ctrl: Timer.Control,
};

pub const timer: *volatile [4]Timer align(4) = @ptrFromInt(gba.mem.io + 0x100);
