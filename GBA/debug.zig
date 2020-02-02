const fmt = @import("std").fmt;

const BIOS = @import("bios.zig").BIOS;

pub const Debug = struct {
    const PrintContext = packed struct {
        request: u16,
        bank: u16,
        get: u16,
        put: u16,
    };

    const AGB_PRINT_PROTECT = @intToPtr(*volatile u16, 0x09FE2FFE);
    const AGB_PRINT_CONTEXT = @intToPtr(*volatile PrintContext, 0x09FE20F8);
    const AGB_PRINT_BUFFER = @intToPtr([*]volatile u16, 0x09FD0000);
    const AGB_BUFFER_SIZE = 0x100;

    pub fn init() void {
        AGB_PRINT_PROTECT.* = 0x20;
        AGB_PRINT_CONTEXT.request = 0x00;
        AGB_PRINT_CONTEXT.get = 0x00;
        AGB_PRINT_CONTEXT.put = 0x00;
        AGB_PRINT_CONTEXT.bank = 0xFD;
        AGB_PRINT_PROTECT.* = 0x00;
    }

    pub fn print(comptime formatString: []const u8, args: var) !void {
        var context = FormatContext{ .written = 0 };
        defer BIOS.debugFlush();
        try fmt.format(&context, fmt.BufPrintError, printOutput, formatString, args);
    }

    pub fn write(message: []const u8) !void {
        defer BIOS.debugFlush();

        if (message.len >= AGB_BUFFER_SIZE) {
            var index: usize = 0;
            while (index < AGB_BUFFER_SIZE) : (index += 1) {
                printChar(message[index]);
            }

            return error.BufferTooSmall;
        }

        for (message) |char| {
            printChar(char);
        }
    }

    fn printChar(value: u8) void {
        var data: u16 = AGB_PRINT_BUFFER[AGB_PRINT_CONTEXT.put >> 1];

        AGB_PRINT_PROTECT.* = 0x20;
        if ((AGB_PRINT_CONTEXT.put & 1) == 1) {
            data = (@intCast(u16, value) << 8) | (data & 0xFF);
        } else {
            data = (data & 0xFF00) | value;
        }
        AGB_PRINT_BUFFER[AGB_PRINT_CONTEXT.put >> 1] = data;
        AGB_PRINT_CONTEXT.put += 1;
        AGB_PRINT_PROTECT.* = 0x00;
    }

    const FormatContext = struct {
        written: usize,
    };

    fn printOutput(context: *FormatContext, bytes: []const u8) !void {
        var remaining = AGB_BUFFER_SIZE - context.written;
        if (remaining < bytes.len) {
            var index: usize = 0;
            while (index < remaining) : (index += 1) {
                printChar(bytes[index]);
            }
            return error.BufferTooSmall;
        }

        for (bytes) |char| {
            printChar(char);
            context.written += 1;
        }
    }
};
