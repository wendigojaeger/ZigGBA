const gba = @import("gba.zig");

/// Up to 32MB of addressable ROM
pub const Rom = [0x02000000]u8;

/// Gamepak ROM is mirrored 3 times, using different access timings as controlled by `access_timings`:
///
/// Wait state 0: `0x08000000..0x0A000000`
///
/// Wait state 1: `0x0A000000..0x0C000000`
///
/// Wait state 2: `0x0C000000..0x0E000000`
pub const rom: *const volatile [3]Rom = @ptrFromInt(gba.mem.rom);

const WaitStateControl = packed struct(u16) {
    pub const AccessTiming = enum(u2) {
        @"4" = 0,
        @"3" = 1,
        @"2" = 2,
        @"8" = 3,
    };

    fn WaitState(comptime T: type) type {
        return packed struct(u3) {
            first: AccessTiming = .@"4",
            second: T = .{},
        };
    }

    sram: AccessTiming = .@"4",
    /// Controls the access timings for ROM when accessed through mirror at 0x08000000
    wait_state_0: WaitState(enum(u1) {
        @"2" = 0,
        @"1" = 1,
    }) = .{},
    /// Controls the access timings for ROM when accessed through mirror at 0x0A000000
    wait_state_1: WaitState(enum(u1) {
        @"4" = 0,
        @"1" = 1,
    }) = .{},
    /// Controls the access timings for ROM when accessed through mirror at 0x0C000000
    wait_state_2: WaitState(enum(u1) {
        @"8" = 0,
        @"1" = 1,
    }) = .{},
    phi_terminal: enum(u2) {
        disable = 0,
        @"4.19MHz" = 1,
        @"8.38MHz" = 2,
        @"16.78MHz" = 3,
    } = .disable,
    _: u1 = 0,
    prefetch: gba.Enable = .disable,
    /// Read-only
    cgb_mode: bool = false,
};

/// Controls access timings for each wait state
pub const access_timings: *volatile WaitStateControl = @ptrFromInt(gba.mem.io + 0x204);

/// Up to 64kB of Save RAM is accessed via 8-bit bus
pub const sram: *volatile [0x10000]u8 = @ptrFromInt(gba.mem.sram);
