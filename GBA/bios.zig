const std = @import("std");
const bufPrint = std.fmt.bufPrint;
const StructField = std.builtin.Type.StructField;
const GBA = @import("core.zig").GBA;
const Math = @import("Math.zig");
const I8_8 = Math.FixedI8_8;
const U8_8 = Math.FixedU8_8;
const Fixed = Math.FixedPoint;
const I2_14 = Fixed(.signed, 2, 14);
const I20_8 = Fixed(.signed, 20, 8);
const BgAffine = @import("Background.zig").BgAffine;

pub const SWI = enum(u8) {
    SoftReset = 0x00,
    RegisterRamReset = 0x01,
    /// Halts CPU until an interrupt request occurs.
    Halt = 0x02,
    /// Very low power mode. CPU, System Clock, Sound, Video,
    /// SIO-Shift Clock, DMAs, and Timers are stopped.
    ///
    /// Only the Keypad, Gamepak, or
    ///
    /// Video, sound, and external hardware should be disabled
    /// before calling.
    Stop = 0x03,
    /// Interrupt handler must add flag at `0x3007FF8h`
    IntrWait = 0x04,
    /// BIOS calls `IntrWait(.DiscardOldFlagsAndWaitNewFlags, InterruptFlags.initOne(.VBlank))`
    ///
    /// Interrupt handler must add flag to 0x3007FF8h
    VBlankIntrWait = 0x05,
    /// Arguments: `.{ numerator, denominator }`
    Div = 0x06,
    /// Arguments: `.{ denominator, numerator }`
    DivArm = 0x07,
    Sqrt = 0x08,
    ArcTan = 0x09,
    ArcTan2 = 0x0A,
    CpuSet = 0x0B,
    CpuFastSet = 0x0C,
    BiosChecksum = 0x0D,
    BgAffineSet = 0x0E,
    ObjAffineSet = 0x0F,

    BitUnpack = 0x10,
    LZ777UnCompWRAM = 0x11,
    LZ777UnCompVRAM = 0x12,
    HuffUnComp = 0x13,
    /// 8 bit writes
    RLUnCompWRAM = 0x14,
    /// 16 bit writes
    RLUnCompVRAM = 0x15,
    /// 8 bit
    Diff8BitUnFilterWRAM = 0x16,
    /// 16 bit
    Diff8BitUnFilterVRAM = 0x17,
    Diff8BitUnFilter = 0x18,
    SoundBiasChange = 0x19,
    SoundDriverInit = 0x1A,
    SoundDriverMode = 0x1B,
    SoundDriverMain = 0x1C,
    /// Short syscall that resets sound DMA
    ///
    /// Call immediately after VBlank interrupt
    SoundDriverVSync = 0x1D,
    SoundChannelClear = 0x1E,
    MIDIKey2Freq = 0x1F,
    /// Undocumented
    MusicPlayerOpen = 0x20,
    /// Undocumented
    MusicPlayerStart = 0x21,
    /// Undocumented
    MusicPlayerStop = 0x22,
    /// Undocumented
    MusicPlayerContinue = 0x23,
    /// Undocumented
    MusicPlayerFadeOut = 0x24,
    MultiBoot = 0x25,
    /// Undocumented
    ///
    /// Very slow
    HardReset = 0x26,
    /// Undocumented
    CustomHalt = 0x27,
    SoundDriverVSyncOff = 0x28,
    SoundDriverVSyncOn = 0x29,
    /// Undocumented
    GetJumpList = 0x2A,

    AGBPrint = 0xFA,

    fn getAsm(code: SWI) []const u8 {
        var buffer: [16]u8 = undefined;
        return bufPrint(&buffer, "swi 0x{X}", .{@intFromEnum(code)}) catch unreachable;
    }

    // zig fmt: off
    // TODO: These could be made into non-tuples
    fn ArgsType(comptime swi: SWI) type {
        return switch (swi) {
            .RegisterRamReset => .{ RamResetFlags },
            .IntrWait => .{ InterruptWaitReturn, GBA.InterruptFlags },
            .Div, .DivArm => .{ i32, i32 },
            .Sqrt => .{ u32 },
            .ArcTan => .{ I2_14 },
            .ArcTan2 => .{ I2_14, I2_14 },
            .CpuSet => .{ *const u32, *u32, CpuSetArgs },
            .CpuFastSet => .{ *const u32, *u32, CpuFastSetArgs },
            .BgAffineSet => .{ *const align(4) BgAffineSource, [*]BgAffine, u32 },
            .ObjAffineSet => .{ *const align(4) ObjAffineSource, *anyopaque, u32, u32 },
            .BitUnpack => .{ *const anyopaque, *const align(4) anyopaque, *const BitUnpackArgs },
            .LZ777UnCompWRAM,
            .LZ777UnCompVRAM,
            .HuffUnComp,
            .RLUnCompWRAM,
            .RLUnCompVRAM,
            .Diff8BitUnFilterWRAM, 
            .Diff8BitUnFilterVRAM,
            .Diff8BitUnFilter => .{ *const DecompressionHeader, *anyopaque },
            // TODO: define actual sound driver struct
            .SoundDriverInit => .{ *const volatile anyopaque },
            .SoundDriverMode => .{ SoundDriverModeArgs },
            // TODO: WaveData*, Midi stuff
            .MIDIKey2Freq => .{ *const anyopaque, u8, u8 },
            .MultiBoot => .{ *const volatile anyopaque, TransferMode },
            else => void,
        };
    }

    fn ReturnType(comptime self: SWI) type {
        return switch (self) {
            .Div, 
            .DivArm => DivResult,
            .BiosChecksum,
            .Sqrt => u16,
            .MIDIKey2Freq => u32,
            .ArcTan, 
            .ArcTan2 => I2_14,
            .MultiBoot => bool,
            else => void,
        };
    }
    pub fn call(comptime self: SWI, args: ArgsType(self)) ReturnType(self) {
        return switch (self) {
            .BiosChecksum,
            .GetJumpList => call0Return1(self),
            .RegisterRamReset, 
            .SoundDriverInit, 
            .SoundDriverMain => call1Return0(self, args),
            .Sqrt, 
            .ArcTan => call1Return1(self, args),
            .IntrWait,
            .LZ777UnCompWRAM,
            .LZ777UnCompVRAM,
            .HuffUnComp,
            .RLUnCompWRAM,
            .RLUnCompVRAM,
            .Diff8BitUnFilterWRAM, 
            .Diff8BitUnFilterVRAM,
            .Diff8BitUnFilter => call2Return0(self, args),
            .ArcTan2 => call2Return1(self, args),
            .Div, 
            .DivArm => call2Return3(self, args),
            .CpuSet, 
            .CPUFastSet, 
            .BgAffineSet, 
            .BitUnpack => call3Return0(self, args),
            .MIDIKey2Freq => call3Return1(self, args),
            .ObjAffineSet => call4Return0(self, args),
            else => call0Return0(self),
        };
    }
    // zig fmt: on

    fn TupleType(comptime info: std.builtin.Type) type {
        return std.meta.Tuple(comptime ty: {
            var types = .{};
            for (info.@"struct".fields) |field| {
                types = types ++ .{field.type};
            }
            break :ty types;
        });
    }

    fn asTuple(comptime args: anytype) TupleType(@TypeOf(args)) {
        const info = comptime @typeInfo(@TypeOf(args)).@"struct";
        return comptime res: {
            const tuple: TupleType(@TypeOf(args)) = undefined;
            for (info.fields, tuple) |field, *r| {
                r.* = @field(args, field.name);
            }
            break :res tuple;
        };
    }

    fn call0Return0(swi: SWI) void {
        const assembly = swi.getAsm();
        asm volatile (assembly);
    }

    fn call0Return1(swi: SWI) ReturnType(swi) {
        const assembly = swi.getAsm();
        const ret: ReturnType(swi) = undefined;
        asm volatile (assembly
            : [ret] "={r0}" (ret),
            :
            : "r0"
        );
    }

    fn call1Return0(swi: SWI, args: ArgsType(swi)) void {
        const assembly = swi.getAsm();
        const r0 = asTuple(args)[0];
        asm volatile (assembly
            :
            : [r0] "{r0}" (r0),
            : "r0"
        );
    }

    fn call1Return1(swi: SWI, args: ArgsType(swi)) ReturnType(swi) {
        const assembly = swi.getAsm();
        const r0 = asTuple(args)[0];
        var ret: ReturnType(swi) = undefined;
        asm volatile (assembly
            : [ret] "={r0}" (ret),
            : [r0] "{r0}" (r0),
            : "r0"
        );
        return ret;
    }

    fn call2Return0(swi: SWI, args: ArgsType(swi)) void {
        const assembly = swi.getAsm();
        const r0, const r1 = asTuple(args);
        asm volatile (assembly
            :
            : [r0] "{r0}" (r0),
              [r1] "{r1}" (r1),
            : "r0", "r1"
        );
    }

    fn call2Return1(swi: SWI, args: ArgsType(swi)) ReturnType(swi) {
        const assembly = swi.getAsm();
        const r0, const r1 = asTuple(args);
        var ret: ReturnType(swi) = undefined;
        asm volatile (assembly
            : [ret] "={r0}" (ret),
            : [r0] "{r0}" (r0),
              [r1] "{r1}" (r1),
            : "r0", "r1"
        );
        return ret;
    }

    // Specialized code for division, as it uses multiple return registers
    fn call2Return3(swi: SWI, args: ArgsType(swi)) DivResult {
        const assembly = swi.getAsm();
        const r0, const r1 = asTuple(args);
        var div: i32 = undefined;
        var rem: i32 = undefined;
        var abs: u32 = undefined;
        asm volatile (assembly
            : [div] "={r0}" (div),
              [rem] "={r1}" (rem),
              [abs] "={r2}" (abs),
            : [r0] "{r0}" (r0),
              [r1] "{r1}" (r1),
            : "r0", "r1", "r2"
        );

        return .{
            .division = div,
            .remainder = rem,
            .absolute_div = abs,
        };
    }

    fn call3Return0(swi: SWI, args: ArgsType(swi)) void {
        const assembly = swi.getAsm();
        const r0, const r1, const r2 = asTuple(args);
        asm volatile (assembly
            :
            : [r0] "{r0}" (r0),
              [r1] "{r1}" (r1),
              [r2] "{r2}" (r2),
            : "r0", "r1", "r2"
        );
    }

    fn call3Return1(swi: SWI, args: ArgsType(swi)) ReturnType(swi) {
        const assembly = swi.getAsm();
        const r0, const r1, const r2 = asTuple(args);
        var ret: ReturnType(swi) = undefined;
        asm volatile (assembly
            : [ret] "={r0}" (ret),
            : [r0] "{r0}" (r0),
              [r1] "{r1}" (r1),
              [r2] "{r2}" (r2),
            : "r0", "r1", "r2"
        );
        return ret;
    }

    fn call4Return0(swi: SWI, args: ArgsType(swi)) void {
        const assembly = swi.getAsm();
        const r0, const r1, const r2, const r3 = asTuple(args);
        asm volatile (assembly
            :
            : [r0] "{r0}" (r0),
              [r1] "{r1}" (r1),
              [r2] "{r2}" (r2),
              [r3] "{r3}" (r3),
            : "r0", "r1", "r2", "r3"
        );
    }
};

pub const RamResetFlags = std.EnumSet(enum {
    ClearEWRAM,
    ClearIWRAM,
    ClearPalette,
    ClearVRAM,
    ClearOAM,
    ResetSIORegisters,
    ResetSoundRegisters,
    ResetOtherRegisters,
});

pub const InterruptWaitReturn = enum(u32) {
    ReturnImmediately,
    DiscardOldFlagsAndWaitNewFlags,
};

pub const DivResult = packed struct { division: i32, remainder: i32, absolute_div: u32 };

pub const CpuSetArgs = packed struct {
    /// the number of words / half-words to write
    count: u21,
    _: u3 = 0,
    /// Whether the write pointer should move with the read pointer
    /// or fill the destination space with the value at src[0]
    fixed_src_addr: enum(u1) {
        Copy,
        Fill,
    },
    data_size: enum(u1) {
        HalfWord,
        Word,
    },
};

pub const CpuFastSetArgs = packed struct {
    /// the number of words to write
    count: u21,
    _: u3 = 0,
    /// Whether the write pointer should move with the read pointer
    /// or fill the destination space with the value at src[0]
    fixed_src_addr: enum(u1) {
        Copy,
        Fill,
    },
};

pub const CompressionType = enum(u4) {
    LZ77 = 1,
    Huffman = 2,
    RunLength = 3,
    DiffFiltered = 8,
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
        Hz5734 = 1,
        Hz7884 = 2,
        Hz10512 = 3,
        Hz13379 = 4,
        Hz15768 = 5,
        Hz18157 = 6,
        Hz21024 = 7,
        Hz26758 = 8,
        Hz31536 = 9,
        Hz36314 = 10,
        Hz40137 = 11,
        Hz42048 = 12,
    } = .Hz13379,
    /// TODO: better representation
    da_bits: u4,
};

pub const TransferMode = enum(u32) {
    Normal256KHz,
    Multiplay,
    Normal2MHz,
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
