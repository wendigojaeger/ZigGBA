const fmt = @import("std").fmt;
const GBA = @import("core.zig").GBA;
const OAM = @import("oam.zig").OAM;

pub const BIOS = struct {
    pub const RamResetFlags = packed struct {
        clearEwRam: bool = false,
        clearIwram: bool = false,
        clearPalette: bool = false,
        clearVRAM: bool = false,
        clearOAM: bool = false,
        resetSIORegisters: bool = false,
        resetSoundRegisters: bool = false,
        resetOtherRegisters: bool = false,

        const Self = @This();

        pub const All = Self{
            .clearEwRam = true,
            .clearIwram = true,
            .clearPalette = true,
            .clearVRAM = true,
            .clearOAM = true,
            .resetSIORegisters = true,
            .resetSoundRegisters = true,
            .resetOtherRegisters = true,
        };
    };

    pub const InterruptWaitReturn = enum(u32) {
        ReturnImmediately,
        DiscardOldFlagsAndWaitNewFlags,
    };

    // TODO: see div() function
    // pub const DivResult = packed struct {
    //     division: i32,
    //     remainder: i32,
    //     absoluteDivision: u32
    // };

    pub const CpuSetArgs = packed struct {
        wordCount: u21,
        dummy: u3 = 0,
        fixedSourceAddress: packed enum(u1) {
            Copy,
            Fill,
        },
        dataSize: packed enum(u1) {
            HalfWord,
            Word,
        },
    };

    pub const CpuFastSetArgs = packed struct {
        wordCount: u21,
        dummy: u3 = 0,
        fixedSourceAddress: packed enum(u1) {
            Copy,
            Fill,
        },
    };

    pub const BgAffineSource = packed struct {
        originalX: i32, // TODO: Use Fixed I19.8
        originalY: i32, // TODO: Use Fixed I19.8,
        displayX: i16,
        displayY: i16,
        scaleX: i16, // TODO: Use Fixed I8.8
        scaleY: i16, // TODO: Use Fixed I8.8
        angle: u16,
    };

    pub const BgAffineDestination = packed struct {
        pa: i16,
        pb: i16,
        pc: i16,
        pd: i16,
        startX: i32, // TODO: Use Fixed I19.8
        startY: i32, // TODO: Use Fixed I19.8
    };

    pub const ObjAffineSource = packed struct {
        scaleX: i16, // TODO: Use Fixed I8.8
        scaleY: i16, // TODO: Use Fixed I8.8
        angle: u16,
    };

    pub const ObjAffineDestination = packed struct {
        pa: i16,
        pb: i16,
        pc: i16,
        pd: i16,
    };

    pub const BitUnpackArgs = packed struct {
        sourceLength: u16,
        sourceBitWidth: u8,
        destinationBitWidth: u8,
        dataOffset: u31,
        zeroData: bool,
    };

    pub inline fn softReset() void {
        systemCall0(0x00);
    }

    pub inline fn registerRamReset(flags: RamResetFlags) void {
        systemCall1(0x01, @bitCast(u8, flags));
    }

    pub inline fn half() void {
        systemCall0(0x02);
    }

    pub inline fn stop() void {
        systemCall0(0x03);
    }

    pub inline fn interruptWait(waitReturn: InterruptWaitReturn, flags: GBA.InterruptFlags) void {
        systemCall2(0x04, @bitCast(u32, waitReturn), @intCast(u32, @bitCast(u14, flags)));
    }

    pub inline fn vblankWait() void {
        systemCall0(5);
    }

    // TODO: div when Zig supports multiple return value in inline assembly https://github.com/ziglang/zig/issues/215
    // pub inline fn div(numerator: i32, denominator: i32) DivResult {
    //     return @bitCast(DivResult, systemCall2Return3(6, @bitCast(u32, numerator), @bitCast(u32, denominator)));
    // }

    // TODO: divArm (swi 7)

    pub inline fn sqrt(value: u32) u16 {
        return @truncate(u16, systemCall1Return(0x08, value));
    }

    pub inline fn arcTan(value: i16) i16 {
        const paramValue =  @intCast(u32, @bitCast(u16, value));
        return @truncate(i16, @bitCast(i32, systemCall1Return(0x09, paramValue)));
    }

    pub inline fn arcTan2(x: i16, y: i16) i16 {
        const paramX = @intCast(u32, @bitCast(u16, x));
        const paramY = @intCast(u32, @bitCast(u16, y));
        return @truncate(i16, @bitCast(i32, systemCall2Return(0x0A, paramX, paramY)));
    }

    pub inline fn cpuSet(source: *const u32, destination: *u32, args: CpuSetArgs) void {
        systemCall3(0x0B, @ptrToInt(source), @ptrToInt(destination), @intCast(u32, @bitCast(u26, args)));
    }

    pub inline fn cpuFastSet(source: *const u32, destination: *u32, args: CpuFastSetArgs) void {
        systemCall3(0x0C, @ptrToInt(source), @ptrToInt(destination), @intCast(u32, @bitCast(u25, args)));
    }

    pub inline fn bgAffineSet(source: *const BgAffineSource, destination: *BgAffineDestination, calculationCount: u32) void {
        systemCall3(0x0E, @ptrToInt(source), @ptrToInt(destination), calculationCount);
    }

    pub inline fn objAffineSetContinuous(source: *const ObjAffineSource, destination: *ObjAffineDestination, calculationCount: u32) void {
        systemCall4(0x0F, @ptrToInt(source), @ptrToInt(destination), calculationCount, 2);
    }

    pub inline fn objAffineSetOam(source: *const ObjAffineSource, destination: *OAM.Affine, calculationCount: u32) void {
        systemCall4(0x0F, @ptrToInt(source), @ptrToInt(destination), calculationCount, 2);
    }

    pub inline fn bitUnpack(source: *const u32, destination: *u32, unpackArgs: *const BitUnpackArgs) void {
        systemCall3(0x10, @ptrToInt(source), @ptrToInt(destination), @ptrToInt(unpackArgs));
    }

    /// Source data needs to be in a specific format, see https://mgba-emu.github.io/gbatek/#lz77uncompreadnormalwrite8bit-wram---swi-11h-gbands7nds9dsi7dsi9
    pub inline fn LZ77UnCompReadNormalWrite8bit(source: *const u32, destination: *u32) void {
        systemCall2(0x11, @ptrToInt(source), @ptrToInt(destination));
    }

    /// Source data needs to be in a specific format, see https://mgba-emu.github.io/gbatek/#lz77uncompreadnormalwrite8bit-wram---swi-11h-gbands7nds9dsi7dsi9
    pub inline fn LZ77UnCompReadNormalWrite16bit(source: *const u32, destination: *u32) void {
        systemCall2(0x12, @ptrToInt(source), @ptrToInt(destination));
    }

    /// Source data needs to be in a specific format, see https://mgba-emu.github.io/gbatek/#huffuncompreadnormal---swi-13h-gba
    pub inline fn huffUnCompReadNormal(source: *const u32, destination: *u32) void {
        systemCall2(0x13, @ptrToInt(source), @ptrToInt(destination));
    }

    /// Source data needs to be in a specific format, see https://mgba-emu.github.io/gbatek/#rluncompreadnormalwrite8bit-wram---swi-14h-gbands7nds9dsi7dsi9
    pub inline fn RLUnCompReadNormalWrite8bit(source: *const u32, destination: *u32) void {
        systemCall2(0x14, @ptrToInt(source), @ptrToInt(destination));
    }

    /// Source data needs to be in a specific format, see https://mgba-emu.github.io/gbatek/#rluncompreadnormalwrite8bit-wram---swi-14h-gbands7nds9dsi7dsi9
    pub inline fn RLUnCompReadNormalWrite16bit(source: *const u32, destination: *u32) void {
        systemCall2(0x15, @ptrToInt(source), @ptrToInt(destination));
    }

    /// Source data needs to be in a specific format, see https://mgba-emu.github.io/gbatek/#diff8bitunfilterwrite8bit-wram---swi-16h-gbands9dsi9
    pub inline fn diff8bitUnFilterWrite8bit(source: *const u32, destination: *u32) void {
        systemCall2(0x16, @ptrToInt(source), @ptrToInt(destination));
    }

    /// Source data needs to be in a specific format, see https://mgba-emu.github.io/gbatek/#diff8bitunfilterwrite8bit-wram---swi-16h-gbands9dsi9
    pub inline fn diff8bitUnFilterWrite16bit(source: *const u32, destination: *u32) void {
        systemCall2(0x17, @ptrToInt(source), @ptrToInt(destination));
    }

    /// Source data needs to be in a specific format, see https://mgba-emu.github.io/gbatek/#diff8bitunfilterwrite8bit-wram---swi-16h-gbands9dsi9
    pub inline fn diff16bitUnFilter(source: *const u32, destination: *u32) void {
        systemCall2(0x18, @ptrToInt(source), @ptrToInt(destination));
    }

    pub inline fn hardReset() void {
        systemCall0(0x26);
    }

    pub inline fn debugFlush() void {
        systemCall0(0xFA);
    }

    pub inline fn systemCall0(comptime call: u8) void {
        const assembly = comptime getSystemCallAssemblyCode(call);

        asm volatile (assembly);
    }

    pub inline fn systemCall1(comptime call: u8, param0: u32) void {
        const assembly = comptime getSystemCallAssemblyCode(call);

        asm volatile (assembly
            :
            : [param0] "{r0}" (param0)
            : "r0"
        );
    }

    pub inline fn systemCall2(comptime call: u8, param0: u32, param1: u32) void {
        const assembly = comptime getSystemCallAssemblyCode(call);

        asm volatile (assembly
            :
            : [param0] "{r0}" (param0),
              [param1] "{r1}" (param1)
            : "r0", "r1"
        );
    }

    pub inline fn systemCall3(comptime call: u8, param0: u32, param1: u32, param2: u32) void {
        const assembly = comptime getSystemCallAssemblyCode(call);

        asm volatile (assembly
            :
            : [param0] "{r0}" (param0),
              [param1] "{r1}" (param1),
              [param2] "{r2}" (param2)
            : "r0", "r1", "r2"
        );
    }

    pub inline fn systemCall4(comptime call: u8, param0: u32, param1: u32, param2: u32, param3: u32) void {
        const assembly = comptime getSystemCallAssemblyCode(call);

        asm volatile (assembly
            :
            : [param0] "{r0}" (param0),
              [param1] "{r1}" (param1),
              [param2] "{r2}" (param2),
              [param3] "{r3}" (param3)
            : "r0", "r1", "r2", "r3"
        );
    }

    pub inline fn systemCall1Return(comptime call: u8, param0: u32) u32 {
        const assembly = comptime getSystemCallAssemblyCode(call);

        return asm volatile (assembly
            : [ret] "={r0}" (-> u32)
            : [param0] "{r0}" (param0)
            : "r0"
        );
    }

    pub inline fn systemCall2Return(comptime call: u8, param0: u32, param1: u32) u32 {
        const assembly = comptime getSystemCallAssemblyCode(call);

        return asm volatile (assembly
            : [ret] "={r0}" (-> u32)
            : [param0] "{r0}" (param0),
              [param1] "{r1}" (param1)
            : "r0", "r1"
        );
    }

    pub inline fn systemCall3Return(comptime call: u8, param0: u32, param1: u32, param2: u32) u32 {
        const assembly = comptime getSystemCallAssemblyCode(call);

        return asm volatile (assembly
            : [ret] "={r0}" (-> u32)
            : [param0] "{r0}" (param0),
              [param1] "{r1}" (param1),
              [param2] "{r2}" (param2)
            : "r0", "r1", "r2"
        );
    }

    inline fn getSystemCallAssemblyCode(comptime call: u8) []const u8 {
        var buffer: [64]u8 = undefined;
        return fmt.bufPrint(buffer[0..], "swi {}", .{call}) catch unreachable;
    }
};
