const std = @import("std");
const zeroes = std.mem.zeroes;
const root = @import("root");
const BIOS = @import("bios.zig").BIOS;

pub const GBA = struct {
    pub const VRAM = @as([*]align(2) volatile u16, @ptrFromInt(0x06000000));
    pub const SPRITE_VRAM = @as([*]align(2) volatile u16, @ptrFromInt(0x06010000));
    pub const OBJ_PALETTE_RAM = @as([*]align(2) volatile u16, @ptrFromInt(0x05000200));
    pub const EWRAM = @as([*]volatile u8, @ptrFromInt(0x02000000));
    pub const IWRAM = @as([*]volatile u8, @ptrFromInt(0x03000000));

    pub const MODE4_FRONT_VRAM = VRAM;
    pub const MODE4_BACK_VRAM = @as([*]align(2) volatile u16, @ptrFromInt(0x0600A000));

    pub const SCREEN_WIDTH = 240;
    pub const SCREEN_HEIGHT = 160;

    pub const MODE3_SCREEN_SIZE = 75 * 1024;
    pub const MODE4_SCREEN_SIZE = 0x9600;
    pub const MODE5_SCREEN_SIZE = 40 * 1024;

    pub const InterruptFlags = packed struct {
        vblank: bool = false,
        hblank: bool = false,
        vcounter: bool = false,
        timer0: bool = false,
        timer1: bool = false,
        timer2: bool = false,
        timer3: bool = false,
        serial: bool = false,
        dma0: bool = false,
        dma1: bool = false,
        dma2: bool = false,
        dma3: bool = false,
        keypad: bool = false,
        gamepak: bool = false,
    };

    pub const Header = extern struct {
        romEntryPoint: u32 align(1) = 0xEA00002E,
        /// Game will not boot if these values are changed.
        nintendoLogo: [156]u8 align(1) = .{
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
        gameName: [12]u8 align(1) = [_]u8{0x00} ** 12,
        gameCode: [4]u8 align(1) = [_]u8{0x00} ** 4,
        makerCode: [2]u8 align(1) = [_]u8{0x00} ** 2,
        /// Cannot be changed
        fixedValue: u8 align(1) = 0x96,
        mainUnitCode: u8 align(1) = 0x00,
        deviceType: u8 align(1) = 0x00,
        reservedArea: [7]u8 align(1) = [_]u8{0x00} ** 7,
        softwareVersion: u8 align(1) = 0x00,
        complementCheck: u8 align(1) = 0x00,
        reservedArea2: [2]u8 align(1) = [_]u8{0x00} ** 2,

        pub fn setup(comptime gameName: []const u8, comptime gameCode: []const u8, comptime makerCode: ?[]const u8, comptime softwareVersion: ?u8) Header {
            var header: Header = .{};

            comptime {
                const isUpper = @import("std").ascii.isUpper;
                const isDigit = @import("std").ascii.isDigit;

                for (gameName, 0..) |value, index| {
                    const validChar = isUpper(value) or isDigit(value);

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

                for (gameCode, 0..) |value, index| {
                    const validChar = isUpper(value);

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
                    for (mCode, 0..) |value, index| {
                        const validChar = isDigit(value);
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

                const computeCheckData = @as([192]u8, @bitCast(header));
                while (index < 0xA0 + (0xBD - 0xA0)) : (index += 1) {
                    complementCheck +%= computeCheckData[index];
                }

                const tempCheck = -(0x19 + @as(i32, @intCast(complementCheck)));
                header.complementCheck = @as(u8, @intCast(tempCheck & 0xFF));
            }

            return header;
        }
    };

    pub inline fn toNativeColor(red: u5, green: u5, blue: u5) u16 {
        return @as(u16, red) | (@as(u16, green) << 5) | (@as(u16, blue) << 10);
    }

    // TODO: maybe put this in IWRAM ?
    pub fn memcpy32(noalias destination: anytype, noalias source: anytype, count: usize) void {
        if (count < 4) {
            genericMemcpy(@as([*]volatile u8, @ptrCast(destination)), @as([*]const u8, @ptrCast(source)), count);
        } else {
            if ((@intFromPtr(@as(*volatile u8, @ptrCast(destination))) % 4) == 0 and (@intFromPtr(@as(*const u8, @ptrCast(source))) % 4) == 0) {
                alignedMemcpy(u32, @as([*]align(4) volatile u8, @ptrCast(@alignCast(destination))), @as([*]align(4) const u8, @ptrCast(@alignCast(source))), count);
            } else if ((@intFromPtr(@as(*volatile u8, @ptrCast(destination))) % 2) == 0 and (@intFromPtr(@as(*const u8, @ptrCast(source))) % 2) == 0) {
                alignedMemcpy(u16, @as([*]align(2) volatile u8, @ptrCast(@alignCast(destination))), @as([*]align(2) const u8, @ptrCast(@alignCast(source))), count);
            } else {
                genericMemcpy(@as([*]volatile u8, @ptrCast(destination)), @as([*]const u8, @ptrCast(source)), count);
            }
        }
    }

    pub fn memcpy16(noalias destination: anytype, noalias source: anytype, count: usize) void {
        if (count < 2) {
            genericMemcpy(@as([*]u8, @ptrCast(destination)), @as([*]const u8, @ptrCast(source)), count);
        } else {
            if ((@intFromPtr(@as(*u8, @ptrCast(destination))) % 2) == 0 and (@intFromPtr(@as(*const u8, @ptrCast(source))) % 2) == 0) {
                alignedMemcpy(u16, @as([*]align(2) volatile u8, @ptrCast(@alignCast(destination))), @as([*]align(2) const u8, @ptrCast(@alignCast(source))), count);
            } else {
                genericMemcpy(@as([*]volatile u8, @ptrCast(destination)), @as([*]const u8, @ptrCast(source)), count);
            }
        }
    }

    pub fn alignedMemcpy(comptime T: type, noalias destination: [*]align(@alignOf(T)) volatile u8, noalias source: [*]align(@alignOf(T)) const u8, count: usize) void {
        @setRuntimeSafety(false);
        const alignSize = count / @sizeOf(T);
        const remainderSize = count % @sizeOf(T);

        const alignDestination = @as([*]volatile T, @ptrCast(destination));
        const alignSource = @as([*]const T, @ptrCast(source));

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
    pub fn memset32(destination: anytype, value: u32, count: usize) void {
        if ((@intFromPtr(@as(*volatile u8, @ptrCast(destination))) % 4) == 0) {
            alignedMemset(u32, @as([*]align(4) volatile u8, @ptrCast(@alignCast(destination))), value, count);
        } else {
            genericMemset(u32, @as([*]volatile u8, @ptrCast(destination)), value, count);
        }
    }

    pub fn memset16(destination: anytype, value: u16, count: usize) void {
        if ((@intFromPtr(@as(*u8, @ptrCast(destination))) % 4) == 0) {
            alignedMemset(u16, @as([*]align(2) volatile u8, @ptrCast(@alignCast(destination))), value, count);
        } else {
            genericMemset(u16, @as([*]volatile u8, @ptrCast(destination)), value, count);
        }
    }

    pub fn alignedMemset(comptime T: type, destination: [*]align(@alignOf(T)) volatile u8, value: T, count: usize) void {
        @setRuntimeSafety(false);
        const alignedDestination = @as([*]volatile T, @ptrCast(destination));
        var index: usize = 0;
        while (index != count) : (index += 1) {
            alignedDestination[index] = value;
        }
    }

    pub fn genericMemset(comptime T: type, destination: [*]volatile u8, value: T, count: usize) void {
        @setRuntimeSafety(false);
        const valueBytes = @as([*]const u8, @ptrCast(&value));
        var index: usize = 0;
        while (index != count) : (index += 1) {
            comptime var expandIndex = 0;
            inline while (expandIndex < @sizeOf(T)) : (expandIndex += 1) {
                destination[(index * @sizeOf(T)) + expandIndex] = valueBytes[expandIndex];
            }
        }
    }
};

export fn GBAMain() linksection(".gbamain") void {
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

fn GBAZigStartup() void {
    // Use BIOS function to clear all data
    BIOS.registerRamReset(BIOS.RamResetFlags.All);

    // Clear .bss
    GBA.memset32(@as([*]volatile u8, @ptrCast(&__bss_start__)), 0, @intFromPtr(&__bss_end__) - @intFromPtr(&__bss_start__));

    // Copy .data section to EWRAM
    GBA.memcpy32(@as([*]volatile u8, @ptrCast(&__data_start__)), @as([*]const u8, @ptrCast(&__data_lma)), @intFromPtr(&__data_end__) - @intFromPtr(&__data_start__));

    // call user's main
    if (@hasDecl(root, "main")) {
        root.main();
    } else {
        while (true) {}
    }
}
