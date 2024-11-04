const std = @import("std");
const bufPrint = std.fmt.bufPrint;
const gba = @import("gba.zig");
const Interrupt = gba.Interrupt;
const math = gba.math;
const I8_8 = math.FixedI8_8;
const U8_8 = math.FixedU8_8;
const I20_8 = math.FixedI20_8;
const I2_14 = math.FixedPoint(.signed, 2, 14);
const Affine = gba.bg.Affine;

pub const SWI = enum(u8) {
    soft_reset = 0x00,
    register_ram_reset = 0x01,
    /// Halts CPU until an interrupt request occurs.
    halt = 0x02,
    /// Very low power mode. CPU, System Clock, Sound, Video,
    /// SIO-Shift Clock, DMAs, and Timers are stopped.
    ///
    /// Only the Keypad, Gamepak, or
    ///
    /// Video, sound, and external hardware should be disabled
    /// before calling.
    stop = 0x03,
    /// Interrupt handler must add flag at `0x3007FF8h`
    intr_wait = 0x04,
    /// BIOS calls `IntrWait(.DiscardOldFlagsAndWaitNewFlags, InterruptFlags.initOne(.VBlank))`
    ///
    /// Interrupt handler must add flag to 0x3007FF8h
    vblank_intr_wait = 0x05,
    /// Arguments: `.{ numerator, denominator }`
    div = 0x06,
    /// Arguments: `.{ denominator, numerator }`
    div_arm = 0x07,
    sqrt = 0x08,
    arctan = 0x09,
    arctan2 = 0x0A,
    cpu_set = 0x0B,
    cpu_fast_set = 0x0C,
    bios_checksum = 0x0D,
    bg_affine_set = 0x0E,
    obj_affine_set = 0x0F,

    bit_unpack = 0x10,
    lz77_uncomp_wram = 0x11,
    lz77_uncomp_vram = 0x12,
    huff_uncomp = 0x13,
    /// 8 bit writes
    rl_uncomp_wram = 0x14,
    /// 16 bit writes
    rl_uncomp_vram = 0x15,
    /// 8 bit
    diff_8bit_unfilter_wram = 0x16,
    /// 16 bit
    diff_8bit_unfilter_vram = 0x17,
    diff_8bit_unfilter = 0x18,
    sound_bias_change = 0x19,
    sound_driver_init = 0x1A,
    sound_driver_mode = 0x1B,
    sound_driver_main = 0x1C,
    /// Short syscall that resets sound DMA
    ///
    /// Call immediately after VBlank interrupt
    sound_driver_vsync = 0x1D,
    sound_channel_clear = 0x1E,
    midi_key_2_freq = 0x1F,
    /// Undocumented
    music_player_open = 0x20,
    /// Undocumented
    music_player_start = 0x21,
    /// Undocumented
    music_player_stop = 0x22,
    /// Undocumented
    music_player_continue = 0x23,
    /// Undocumented
    music_player_fade_out = 0x24,
    multi_boot = 0x25,
    /// Undocumented
    ///
    /// Very slow
    hard_reset = 0x26,
    /// Undocumented
    custom_halt = 0x27,
    sound_driver_vsync_off = 0x28,
    sound_driver_vsync_on = 0x29,
    /// Undocumented
    get_jump_list = 0x2A,

    agb_print = 0xFA,

    // TODO: add a way to
    fn getAsm(comptime code: SWI) []const u8 {
        var buffer: [16]u8 = undefined;
        return bufPrint(&buffer, "swi 0x{X}", .{@intFromEnum(code)}) catch unreachable;
    }

    fn ReturnType(comptime self: SWI) type {
        return switch (self) {
            .div, .div_arm => DivResult,
            .bios_checksum, .sqrt => u16,
            .midi_key_2_freq => u32,
            .arctan, .arctan2 => I2_14,
            .multi_boot => bool,
            else => void,
        };
    }
};

pub const RamResetFlags = std.EnumSet(enum {
    clear_ewram,
    clear_iwram,
    clear_palette,
    clear_vram,
    clear_oam,
    reset_sio_registers,
    reset_sound_registers,
    reset_other_registers,
});

pub const DivResult = packed struct { division: i32, remainder: i32, absolute_div: u32 };

/// Whether the write pointer should move with the read pointer
/// or fill the destination space with the value at src[0]
const FixedSourceAddr = enum(u1) {
    copy,
    fill,
};

const CpuSetSize = enum(u1) {
    half_word,
    word,

    fn alignment(self: CpuSetSize) u29 {
        return switch (self) {
            .half_word => 2,
            .word => 4,
        };
    }
};

pub const CpuSet = union(enum) {
    half_Word: []align(2) anyopaque,
    word: []align(4) anyopaque,
};

const CpuSetArgs = packed struct {
    /// the number of words / half-words to write
    count: u21,
    _: u3 = 0,
    /// Whether the write pointer should move with the read pointer
    /// or fill the destination space with the value at src[0]
    fixed_src_addr: FixedSourceAddr,
    data_size: enum(u1) {
        half_word,
        word,
    },
};

pub const CpuFastSetArgs = packed struct {
    /// the number of words to write
    count: u21,
    _: u3 = 0,
    /// Whether the write pointer should move with the read pointer
    /// or fill the destination space with the value at src[0]
    fixed_src_addr: FixedSourceAddr,
};

pub const CompressionType = enum(u4) {
    lz77 = 1,
    huffman = 2,
    run_length = 3,
    diff_filtered = 8,
};

pub const DecompressionHeader = packed struct(u32) {
    data_size: u4 = 0,
    type: CompressionType,
    decompressed_size: u24,
};

pub const SoundDriverModeArgs = packed struct(u32) {
    reverb_value: u7 = 0,
    apply_reverb: bool,
    simultaneous_channels: u4 = 8,
    master_volume: u4 = 15,
    frequency: enum(u4) {
        @"5734_hz" = 1,
        @"7884_hz" = 2,
        @"10512_hz" = 3,
        @"13379_hz" = 4,
        @"15768_hz" = 5,
        @"18157_hz" = 6,
        @"21024_hz" = 7,
        @"26758_hz" = 8,
        @"31536_hz" = 9,
        @"36314_hz" = 10,
        @"40137_hz" = 11,
        @"42048_hz" = 12,
    } = .@"13379_hz",
    /// TODO: better representation
    da_bits: u4,
};

pub const TransferMode = enum(u32) {
    normal_256_khz,
    multiplay,
    normal_2_mhz,
};

pub const BgAffineSource = extern struct {
    original_x: I20_8 align(4),
    original_y: I20_8 align(4),
    display_x: i16,
    display_y: i16,
    scale_x: I8_8,
    scale_y: I8_8,
    /// BIOS ignores fractional part
    angle: U8_8,
};

pub const ObjAffineSource = packed struct {
    scale_x: I8_8,
    scale_y: I8_8,
    /// BIOS ignores fractional part
    angle: U8_8,
};

pub const BitUnpackArgs = packed struct {
    src_len: u16,
    src_bit_width: u8,
    dest_bit_width: u8,
    data_offset: u31,
    zero_data: bool,
};

// TODO: These could be made into non-tuples
pub fn resetRamRegisters(flags: RamResetFlags) void {
    call1Return0(.register_ram_reset, flags);
}

pub fn waitInterrupt(return_type: Interrupt.WaitReturn, flags: Interrupt.Flags) void {
    call2Return0(.intr_wait, .{ return_type, flags });
}

pub fn waitVBlank() void {
    // TODO: The bios just loads these arguments on the registers and calls IntrWait
    // So this might be better if you're not hand-writing assembly?
    // call2Return0(.intr_wait, .{ .discard_old_wait_new, GBA.InterruptFlags.initOne(.vblank) });
    call0Return0(.vblank_intr_wait);
}

pub fn div(numerator: i32, denominator: i32) DivResult {
    return call2Return3(.div, .{ numerator, denominator });
}

/// 3 cycles slower than div
pub fn divArm(numerator: i32, denominator: i32) DivResult {
    return call2Return3(.div_arm, .{ denominator, numerator });
}

pub fn sqrt(x: u32) u16 {
    return call1Return1(.sqrt, x);
}

pub fn arctan(x: I2_14) I2_14 {
    return call1Return1(.arctan, x);
}

pub fn arctan2(x: I2_14, y: I2_14) I2_14 {
    return call2Return1(.arctan2, .{ x, y });
}

// TODO: Consider whether these could be turned into comptime slices
//pub fn cpuSetHalfWord(source: []const volatile)

//pub fn cpuFastSet(src: *const align(4) anyopaque)
// .CpuSet => .{ *const u32, *u32, CpuSetArgs },
// .CpuFastSet => .{ *const u32, *u32, CpuFastSetArgs },
// .BgAffineSet => .{ *const align(4) BgAffineSource, [*]BgAffine, u32 },
// .ObjAffineSet => .{ *const align(4) ObjAffineSource, *anyopaque, u32, u32 },
// .BitUnpack => .{ *const anyopaque, *const align(4) anyopaque, *const BitUnpackArgs },
// .LZ777UnCompWRAM,
// .LZ777UnCompVRAM,
// .HuffUnComp,
// .RLUnCompWRAM,
// .RLUnCompVRAM,
// .Diff8BitUnFilterWRAM,
// .Diff8BitUnFilterVRAM,
// .Diff8BitUnFilter => .{ *const DecompressionHeader, *anyopaque },
// // TODO: define actual sound driver struct
// .SoundDriverInit => .{ *const volatile anyopaque },
// .SoundDriverMode => .{ SoundDriverModeArgs },
// // TODO: WaveData*, Midi stuff
// .MIDIKey2Freq => .{ *const anyopaque, u8, u8 },
// .MultiBoot => .{ *const volatile anyopaque, TransferMode },
// else => void,

pub fn debugFlush() void {
    call0Return0(.agb_print);
}

fn call0Return0(comptime swi: SWI) void {
    const assembly = comptime swi.getAsm();
    asm volatile (assembly);
}

fn call0Return1(comptime swi: SWI) swi.ReturnType() {
    const assembly = comptime swi.getAsm();
    const ret: swi.ReturnType() = undefined;
    asm volatile (assembly
        : [ret] "={r0}" (ret),
        :
        : "r0"
    );
}

inline fn call1Return0(comptime swi: SWI, r0: anytype) void {
    const assembly = comptime swi.getAsm();
    return asm volatile (assembly
        :
        : [r0] "{r0}" (r0),
        : "r0"
    );
}

fn call1Return1(comptime swi: SWI, r0: anytype) swi.ReturnType() {
    const assembly = comptime swi.getAsm();
    var ret: swi.ReturnType() = undefined;
    asm volatile (assembly
        : [ret] "={r0}" (ret),
        : [r0] "{r0}" (r0),
        : "r0"
    );
    return ret;
}

fn call2Return0(comptime swi: SWI, args: anytype) void {
    const assembly = comptime swi.getAsm();
    const r0, const r1 = args;
    asm volatile (assembly
        :
        : [r0] "{r0}" (r0),
          [r1] "{r1}" (r1),
        : "r0", "r1"
    );
}

fn call2Return1(comptime swi: SWI, r0: anytype, r1: anytype) swi.ReturnType() {
    const assembly = comptime swi.getAsm();
    var ret: swi.ReturnType() = undefined;
    asm volatile (assembly
        : [ret] "={r0}" (ret),
        : [r0] "{r0}" (r0),
          [r1] "{r1}" (r1),
        : "r0", "r1"
    );
    return ret;
}

// Specialized code for division, as it uses multiple return registers
fn call2Return3(comptime swi: SWI, r0: i32, r1: i32) DivResult {
    const assembly = comptime swi.getAsm();
    var quo: i32 = undefined;
    var rem: i32 = undefined;
    var abs: u32 = undefined;
    asm volatile (assembly
        : [quo] "={r0}" (quo),
          [rem] "={r1}" (rem),
          [abs] "={r2}" (abs),
        : [r0] "{r0}" (r0),
          [r1] "{r1}" (r1),
        : "r0", "r1", "r2"
    );

    return .{
        .division = quo,
        .remainder = rem,
        .absolute_div = abs,
    };
}

fn call3Return0(comptime swi: SWI, r0: anytype, r1: anytype, r2: anytype) void {
    const assembly = comptime swi.getAsm();
    asm volatile (assembly
        :
        : [r0] "{r0}" (r0),
          [r1] "{r1}" (r1),
          [r2] "{r2}" (r2),
        : "r0", "r1", "r2"
    );
}

fn call3Return1(comptime swi: SWI, r0: anytype, r1: anytype, r2: anytype) swi.ReturnType() {
    const assembly = comptime swi.getAsm();
    var ret: swi.ReturnType() = undefined;
    asm volatile (assembly
        : [ret] "={r0}" (ret),
        : [r0] "{r0}" (r0),
          [r1] "{r1}" (r1),
          [r2] "{r2}" (r2),
        : "r0", "r1", "r2"
    );
    return ret;
}

fn call4Return0(comptime swi: SWI, r0: anytype, r1: anytype, r2: anytype, r3: anytype) void {
    const assembly = comptime swi.getAsm();
    asm volatile (assembly
        :
        : [r0] "{r0}" (r0),
          [r1] "{r1}" (r1),
          [r2] "{r2}" (r2),
          [r3] "{r3}" (r3),
        : "r0", "r1", "r2", "r3"
    );
}
