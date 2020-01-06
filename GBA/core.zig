const root = @import("root");

pub const GBA = struct {
    pub const VRAM = @intToPtr([*]volatile u16, 0x06000000);
    pub const SPRITE_VRAM = @intToPtr([*]volatile u16, 0x06010000);
    pub const BG_PALETTE_RAM = @intToPtr([*]volatile u16, 0x05000000);
    pub const OBJ_PALETTE_RAM = @intToPtr([*]volatile u16, 0x05000200);
    pub const EWRAM = @intToPtr([*]volatile u8, 0x02000000);
    pub const IWRAM = @intToPtr([*]volatile u8, 0x03000000);
    pub const OAM = @intToPtr([*]volatile u16, 0x07000000);

    pub const MEM_IO = @intToPtr(*volatile u32, 0x04000000);
    pub const REG_DISPCNT = @intToPtr(*volatile u16, @ptrToInt(MEM_IO) + 0x0000);
    pub const REG_DISPSTAT = @intToPtr(*volatile u16, @ptrToInt(MEM_IO) + 0x0004);
    pub const REG_VCOUNT = @intToPtr(*volatile u16, @ptrToInt(MEM_IO) + 0x0006);
    pub const REG_KEYINPUT = @intToPtr(*volatile u16, @ptrToInt(MEM_IO) + 0x0130);

    pub const MODE4_FRONT_VRAM = VRAM;
    pub const MODE4_BACK_VRAM = @intToPtr([*]volatile u16, 0x0600A000);

    pub const SCREEN_WIDTH = 240;
    pub const SCREEN_HEIGHT = 160;

    pub const MODE3_SCREEN_SIZE = 75 * 1024;
    pub const MODE4_SCREEN_SIZE = 0x9600;
    pub const MODE5_SCREEN_SIZE = 40 * 1024;

    pub const PaletteMode = enum(u1) {
        Color16,
        Color256,
    };

    pub const Header = packed struct {
        romEntryPoint: u32,
        nintendoLogo: [156]u8,
        gameName: [12]u8,
        gameCode: [4]u8,
        makerCode: [2]u8,
        fixedValue: u8,
        mainUnitCode: u8,
        deviceType: u8,
        reservedArea: [7]u8,
        softwareVersion: u8,
        complementCheck: u8,
        reservedArea2: [2]u8,

        pub fn setup(comptime gameName: []const u8, comptime gameCode: []const u8, comptime makerCode: ?[]const u8, comptime softwareVersion: ?u8) Header {
            var header = Header{
                .romEntryPoint = 0xEA00002E,
                .nintendoLogo = .{
                    0x24, 0xFF, 0xAE, 0x51, 0x69, 0x9A, 0xA2, 0x21, 0x3D, 0x84, 0x82, 0x0A, 0x84, 0xE4, 0x09, 0xAD,
                    0x11, 0x24, 0x8B, 0x98, 0xC0, 0x81, 0x7F, 0x21, 0xA3, 0x52, 0xBE, 0x19, 0x93, 0x09, 0xCE, 0x20,
                    0x10, 0x46, 0x4A, 0x4A, 0xF8, 0x27, 0x31, 0xEC, 0x58, 0xC7, 0xE8, 0x33, 0x82, 0xE3, 0xCE, 0xBF,
                    0x85, 0xF4, 0xDF, 0x94, 0xCE, 0x4B, 0x09, 0xC1, 0x94, 0x56, 0x8A, 0xC0, 0x13, 0x72, 0xA7, 0xFC,
                    0x9F, 0x84, 0x4D, 0x73, 0xA3, 0xCA, 0x9A, 0x61, 0x58, 0x97, 0xA3, 0x27, 0xFC, 0x03, 0x98, 0x76,
                    0x23, 0x1D, 0xC7, 0x61, 0x03, 0x04, 0xAE, 0x56, 0xBF, 0x38, 0x84, 0x00, 0x40, 0xA7, 0x0E, 0xFD,
                    0xFF, 0x52, 0xFE, 0x03, 0x6F, 0x95, 0x30, 0xF1, 0x97, 0xFB, 0xC0, 0x85, 0x60, 0xD6, 0x80, 0x25,
                    0xA9, 0x63, 0xBE, 0x03, 0x01, 0x4E, 0x38, 0xE2, 0xF9, 0xA2, 0x34, 0xFF, 0xBB, 0x3E, 0x03, 0x44,
                    0x78, 0x00, 0x90, 0xCB, 0x88, 0x11, 0x3A, 0x94, 0x65, 0xC0, 0x7C, 0x63, 0x87, 0xF0, 0x3C, 0xAF,
                    0xD6, 0x25, 0xE4, 0x8B, 0x38, 0x0A, 0xAC, 0x72, 0x21, 0xD4, 0xF8, 0x07,
                },
                .gameName = [_]u8{0} ** 12,
                .gameCode = [_]u8{0} ** 4,
                .makerCode = [_]u8{0} ** 2,
                .fixedValue = 0x96,
                .mainUnitCode = 0x00,
                .deviceType = 0x00,

                .reservedArea = [_]u8{0} ** 7,
                .softwareVersion = 0x00,
                .complementCheck = 0x00,
                .reservedArea2 = [_]u8{0} ** 2,
            };

            comptime {
                const isUpper = @import("std").ascii.isUpper;
                const isDigit = @import("std").ascii.isDigit;

                for (gameName) |value, index| {
                    var validChar = isUpper(value) or isDigit(value);

                    if (validChar and index < 12) {
                        header.gameName[index] = value;
                    } else {
                        if (index >= 12) {
                            @compileError("Game name is too long, it needs to be no longer than 12 characters.");
                        } else if (!validChar) {
                            @compileError("Game name needs to be in uppercase, it can use digits.");
                        }
                    }
                }

                for (gameCode) |value, index| {
                    var validChar = isUpper(value);

                    if (validChar and index < 4) {
                        header.gameCode[index] = value;
                    } else {
                        if (index >= 4) {
                            @compileError("Game code is too long, it needs to be no longer than 4 characters.");
                        } else if (!validChar) {
                            @compileError("Game code needs to be in uppercase.");
                        }
                    }
                }

                if (makerCode) |mCode| {
                    for (mCode) |value, index| {
                        var validChar = isDigit(value);
                        if (validChar and index < 2) {
                            header.makerCode[index] = value;
                        } else {
                            if (index >= 2) {
                                @compileError("Maker code is too long, it needs to be no longer than 2 characters.");
                            } else if (!validChar) {
                                @compileError("Maker code needs to be digits.");
                            }
                        }
                    }
                }

                header.softwareVersion = softwareVersion orelse 0;

                var complementCheck: u8 = 0;
                var index: usize = 0xA0;

                var computeCheckData = @bitCast([192]u8, header);
                while (index < 0xA0 + (0xBD - 0xA0)) : (index += 1) {
                    complementCheck +%= computeCheckData[index];
                }

                var tempCheck = -(0x19 + @intCast(i32, complementCheck));
                header.complementCheck = @intCast(u8, tempCheck & 0xFF);
            }

            return header;
        }
    };

    pub inline fn toNativeColor(red: u8, green: u8, blue: u8) u16 {
        return @as(u16, red & 0x1f) | (@as(u16, green & 0x1f) << 5) | (@as(u16, blue & 0x1f) << 10);
    }

    pub const RamResetFlags = struct {
        pub const clearEwRam = 1 << 0;
        pub const clearIwram = 1 << 1;
        pub const clearPalette = 1 << 2;
        pub const clearVRAM = 1 << 3;
        pub const clearOAM = 1 << 4;
        pub const resetSIORegisters = 1 << 5;
        pub const resetSoundRegisters = 1 << 6;
        pub const resetOtherRegisters = 1 << 7;

        const All = clearEwRam | clearIwram | clearPalette | clearVRAM | clearOAM | resetSIORegisters | resetSoundRegisters | resetOtherRegisters;
    };

    // TODO: Figure out how to pass the reset flags and don't get eaten up by the optimizer
    pub fn BIOSRegisterRamReset() void {
        asm volatile (
            \\movs r0, #0xFF
            \\swi 1
        );
    }

    // TODO: maybe put this in IWRAM ?
    pub fn memcpy32(noalias destination: var, noalias source: var, count: usize) void {
        if (count < 4) {
            genericMemcpy(@ptrCast([*]u8, destination), @ptrCast([*]const u8, source), count);
        } else {
            if ((@ptrToInt(@ptrCast(*u8, destination)) % 4) == 0 and (@ptrToInt(@ptrCast(*const u8, source)) % 4) == 0) {
                alignedMemcpy(u32, @ptrCast([*]align(4) volatile u8, @alignCast(4, destination)), @ptrCast([*]align(4) const u8, @alignCast(4, source)), count);
            } else if ((@ptrToInt(@ptrCast(*u8, destination)) % 2) == 0 and (@ptrToInt(@ptrCast(*const u8, source)) % 2) == 0) {
                alignedMemcpy(u16, @ptrCast([*]align(2) volatile u8, @alignCast(2, destination)), @ptrCast([*]align(2) const u8, @alignCast(2, source)), count);
            } else {
                genericMemcpy(@ptrCast([*]volatile u8, destination), @ptrCast([*]const u8, source), count);
            }
        }
    }

    pub fn memcpy16(noalias destination: var, noalias source: var, count: usize) void {
        if (count < 2) {
            genericMemcpy(@ptrCast([*]u8, destination), @ptrCast([*]const u8, source), count);
        } else {
            if ((@ptrToInt(@ptrCast(*u8, destination)) % 2) == 0 and (@ptrToInt(@ptrCast(*const u8, source)) % 2) == 0) {
                alignedMemcpy(u16, @ptrCast([*]align(2) volatile u8, @alignCast(2, destination)), @ptrCast([*]align(2) const u8, @alignCast(2, source)), count);
            } else {
                genericMemcpy(@ptrCast([*]volatile u8, destination), @ptrCast([*]const u8, source), count);
            }
        }
    }

    pub fn alignedMemcpy(comptime T: type, noalias destination: [*]align(@alignOf(T)) volatile u8, noalias source: [*]align(@alignOf(T)) const u8, count: usize) void {
        @setRuntimeSafety(false);
        const alignSize = count / @sizeOf(T);
        const remainderSize = count % @sizeOf(T);

        const alignDestination = @ptrCast([*]volatile T, destination);
        const alignSource = @ptrCast([*]const T, source);

        var index: usize = 0;
        while (index != alignSize) : (index += 1) {
            alignDestination[index] = alignSource[index];
        }

        index = count - remainderSize;
        while (index != count) : (index += 1) {
            destination[index] = source[index];
        }
    }

    pub fn genericMemcpy(noalias destination: [*]volatile u8, noalias source: [*]const u8, count: usize) void {
        @setRuntimeSafety(false);
        var index: usize = 0;
        while (index != count) : (index += 1) {
            destination[index] = source[index];
        }
    }

    // TODO: maybe put it in IWRAM ?
    pub fn memset32(destination: var, value: u32, count: usize) void {
        if ((@ptrToInt(@ptrCast(*u8, destination)) % 4) == 0) {
            alignedMemset(u32, @ptrCast([*]align(4) volatile u8, @alignCast(4, destination)), value, count);
        } else {
            genericMemset(u32, @ptrCast([*]volatile u8, destination), value, count);
        }
    }

    pub fn memset16(destination: var, value: u16, count: usize) void {
        if ((@ptrToInt(@ptrCast(*u8, destination)) % 4) == 0) {
            alignedMemset(u16, @ptrCast([*]align(2) volatile u8, @alignCast(2, destination)), value, count);
        } else {
            genericMemset(u16, @ptrCast([*]volatile u8, destination), value, count);
        }
    }

    pub fn alignedMemset(comptime T: type, destination: [*]align(@alignOf(T)) volatile u8, value: T, count: usize) void {
        @setRuntimeSafety(false);
        const alignedDestination = @ptrCast([*]volatile T, destination);
        var index: usize = 0;
        while (index != count) : (index += 1) {
            alignedDestination[index] = value;
        }
    }

    pub fn genericMemset(comptime T: type, destination: [*]volatile u8, value: T, count: usize) void {
        @setRuntimeSafety(false);
        const valueBytes = @ptrCast([*]const u8, &value);
        var index: usize = 0;
        while (index != count) : (index += 1) {
            comptime var expandIndex = 0;
            inline while (expandIndex < @sizeOf(T)) : (expandIndex += 1) {
                destination[(index * @sizeOf(T)) + expandIndex] = valueBytes[expandIndex];
            }
        }
    }
};

export nakedcc fn GBAMain() linksection(".gbamain") noreturn {
    // Assembly init code
    asm volatile (
        \\.arm
        \\.cpu arm7tdmi
        \\mov r0, #0x4000000
        \\str r0, [r0, #0x208]
        \\
        \\mov r0, #0x12
        \\msr cpsr, r0
        \\ldr sp, =__sp_irq
        \\mov r0, #0x1f
        \\msr cpsr, r0
        \\ldr sp, =__sp_usr
        \\add r0, pc, #1
        \\bx r0
    );

    GBAZigStartup();
}

extern var __bss_lma: u8;
extern var __bss_start__: u8;
extern var __bss_end__: u8;
extern var __data_lma: u8;
extern var __data_start__: u8;
extern var __data_end__: u8;

fn GBAZigStartup() noreturn {
    // Use BIOS function to clear all data
    GBA.BIOSRegisterRamReset();

    // Clear .bss
    GBA.memset32(@ptrCast([*]volatile u8, &__bss_start__), 0, @ptrToInt(&__bss_end__) - @ptrToInt(&__bss_start__));

    // Copy .data section to EWRAM
    GBA.memcpy32(@ptrCast([*]volatile u8, &__data_start__), @ptrCast([*]const u8, &__data_lma), @ptrToInt(&__data_end__) - @ptrToInt(&__data_start__));

    // call user's main
    if (@hasDecl(root, "main")) {
        root.main();
    } else {
        while (true) {}
    }
}
