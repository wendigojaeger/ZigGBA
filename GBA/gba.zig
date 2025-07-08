const std = @import("std");
const root = @import("root");
const gba = @This();

pub const bg = @import("bg.zig");
pub const bios = @import("bios.zig");
pub const bitmap = @import("bitmap.zig");
pub const Color = @import("color.zig").Color;
pub const debug = @import("debug.zig");
pub const display = @import("display.zig");
pub const input = @import("input.zig");
pub const interrupt = @import("interrupt.zig");
pub const math = @import("math.zig");
pub const mem = @import("mem.zig");
pub const obj = @import("obj.zig");
pub const sound = @import("sound.zig");
pub const timer = @import("timer.zig");
pub const utils = @import("utils.zig");

pub const ewram: *volatile [0x20000]u16 = @ptrFromInt(gba.mem.ewram);
pub const iwram: *volatile [0x2000]u32 = @ptrFromInt(gba.mem.iwram);

pub const screen_width = 240;
pub const screen_height = 160;

const Header = extern struct {
    rom_entry_point: u32 align(1) = 0xEA00002E,
    /// Game will not boot if these values are changed.
    nintendo_logo: [156]u8 align(1) = .{
        0x24, 0xFF, 0xAE, 0x51, 0x69, 0x9A, 0xA2, 0x21, 0x3D, 0x84, 0x82, 0x0A, 0x84,
        0xE4, 0x09, 0xAD, 0x11, 0x24, 0x8B, 0x98, 0xC0, 0x81, 0x7F, 0x21, 0xA3, 0x52,
        0xBE, 0x19, 0x93, 0x09, 0xCE, 0x20, 0x10, 0x46, 0x4A, 0x4A, 0xF8, 0x27, 0x31,
        0xEC, 0x58, 0xC7, 0xE8, 0x33, 0x82, 0xE3, 0xCE, 0xBF, 0x85, 0xF4, 0xDF, 0x94,
        0xCE, 0x4B, 0x09, 0xC1, 0x94, 0x56, 0x8A, 0xC0, 0x13, 0x72, 0xA7, 0xFC, 0x9F,
        0x84, 0x4D, 0x73, 0xA3, 0xCA, 0x9A, 0x61, 0x58, 0x97, 0xA3, 0x27, 0xFC, 0x03,
        0x98, 0x76, 0x23, 0x1D, 0xC7, 0x61, 0x03, 0x04, 0xAE, 0x56, 0xBF, 0x38, 0x84,
        0x00, 0x40, 0xA7, 0x0E, 0xFD, 0xFF, 0x52, 0xFE, 0x03, 0x6F, 0x95, 0x30, 0xF1,
        0x97, 0xFB, 0xC0, 0x85, 0x60, 0xD6, 0x80, 0x25, 0xA9, 0x63, 0xBE, 0x03, 0x01,
        0x4E, 0x38, 0xE2, 0xF9, 0xA2, 0x34, 0xFF, 0xBB, 0x3E, 0x03, 0x44, 0x78, 0x00,
        0x90, 0xCB, 0x88, 0x11, 0x3A, 0x94, 0x65, 0xC0, 0x7C, 0x63, 0x87, 0xF0, 0x3C,
        0xAF, 0xD6, 0x25, 0xE4, 0x8B, 0x38, 0x0A, 0xAC, 0x72, 0x21, 0xD4, 0xF8, 0x07,
    },
    game_name: [12]u8 align(1) = @splat(0),
    game_code: [4]u8 align(1) = @splat(0),
    maker_code: [2]u8 align(1) = @splat(0),
    /// Cannot be changed
    fixed_value: u8 align(1) = 0x96,
    main_unit_code: u8 align(1) = 0x00,
    device_type: u8 align(1) = 0x00,
    _: [7]u8 align(1) = @splat(0),
    software_version: u8 align(1) = 0x00,
    complement_check: u8 align(1) = 0x00,
};

pub fn initHeader(comptime game_name: []const u8, comptime game_code: []const u8, comptime maker_code: ?[]const u8, comptime software_version: ?u8) Header {
    comptime {
        var header: Header = .{};
        const isUpper = std.ascii.isUpper;
        const isDigit = std.ascii.isDigit;

        if (game_name.len > 12) {
            @compileError("Game name must be no longer than 12 characters.");
        }
        for (game_name, header.game_name[0..game_name.len]) |value, *byte| {
            if (isUpper(value) or isDigit(value)) {
                byte.* = value;
            } else {
                @compileError("Game name needs to be in uppercase, it can use digits.");
            }
        }

        if (game_code.len > 4) {
            @compileError("Game code must be no longer than 4 characters.");
        }

        for (game_code, header.game_code[0..game_code.len]) |value, *byte| {
            if (isUpper(value)) {
                byte.* = value;
            } else {
                @compileError("Game code needs to be in uppercase.");
            }
        }

        if (maker_code) |m_code| {
            if (m_code.len > 2) {
                @compileError("Maker code must be no longer than 2 characters.");
            }
            for (m_code, header.maker_code[0..m_code.len]) |value, *byte| {
                if (isDigit(value)) {
                    byte.* = value;
                } else {
                    @compileError("Maker code needs to be digits.");
                }
            }
        }

        header.software_version = software_version orelse 0;

        var complement_check: u8 = 0;
        for (std.mem.asBytes(&header)[0xA0..0xBD]) |byte| {
            complement_check +%= byte;
        }

        const temp_check = -(0x19 + @as(i32, @intCast(complement_check)));
        header.complement_check = @bitCast(@as(i8, @truncate(temp_check)));
        return header;
    }
}

extern var __bss_lma: u8;
extern var __bss_start__: u8;
extern var __bss_end__: u8;
extern var __data_lma: u8;
extern var __data_start__: u8;
extern var __data_end__: u8;

export fn _start() noreturn {
    // Assembly init code
    asm volatile (
        \\.arm
        \\.cpu arm7tdmi
        \\mov r0, #0x4000000
        \\str r0, [r0, #0x208]
        \\
        \\mov r0, #0x12
        \\msr cpsr, r0
        \\ldr sp, _start_sp_irq_word
        \\mov r0, #0x1f
        \\msr cpsr, r0
        \\ldr sp, _start_sp_usr_word
        \\adr r0, #1 + _start_zig
        \\bx r0
        // Ensure _sq_irq and _sq_usr are defined near enough
        // to the entry point to be referenced with `ldr` above.
        \\  .align 4
        \\_start_sp_irq_word: .word __sp_irq
        \\_start_sp_usr_word: .word __sp_usr
        \\_start_zig:
    );

    // Use BIOS function to clear all data
    bios.resetRamRegisters(bios.RamResetFlags.initFull());
    // Clear .bss
    mem.memset32(&__bss_start__, 0, @intFromPtr(&__bss_end__) - @intFromPtr(&__bss_start__));

    // Copy .data section to EWRAM
    mem.memcpy32(&__data_start__, &__data_lma, @intFromPtr(&__data_end__) - @intFromPtr(&__data_start__));

    // call user's main
    if (@hasDecl(root, "main")) {
        root.main();
    }
    while (true) {}
}
