const std = @import("std");
const fmt = std.fmt;
const Writer = std.io.Writer;
const gba = @import("gba.zig");
const bios = gba.bios;

const PrintContext = packed struct {
    request: u16,
    bank: u16,
    get: u16,
    put: u16,
};

const DebugStream = struct {
    written: usize,

    pub fn init() DebugStream {
        return DebugStream{
            .written = 0,
        };
    }

    pub fn write(self: *DebugStream, bytes: []const u8) !usize {
        const remaining = AGB_BUFFER_SIZE - self.written;
        if (remaining < bytes.len) {
            for (bytes[0..remaining]) |c| {
                printChar(c);
            }
            return error.BufferTooSmall;
        }

        var written: usize = 0;
        for (bytes) |char| {
            printChar(char);
            self.written += 1;
            written += 1;
        }

        return written;
    }

    pub fn outStream(self: *DebugStream) Writer(*DebugStream, error{BufferTooSmall}, DebugStream.write) {
        return .{ .context = self };
    }
};

const AGB_PRINT_PROTECT: *volatile u16 = @ptrFromInt(0x09FE2FFE);
const AGB_PRINT_CONTEXT: *volatile PrintContext = @ptrFromInt(0x09FE20F8);
const AGB_PRINT_BUFFER: [*]volatile u16 = @ptrFromInt(0x09FD0000);
const AGB_BUFFER_SIZE = 0x100;

pub fn init() void {
    AGB_PRINT_PROTECT.* = 0x00;
    AGB_PRINT_CONTEXT.request = 0x00;
    AGB_PRINT_CONTEXT.get = 0x00;
    AGB_PRINT_CONTEXT.put = 0x00;
    AGB_PRINT_CONTEXT.bank = 0xFD;
    AGB_PRINT_PROTECT.* = 0x00;
}

pub fn print(comptime formatString: []const u8, args: anytype) !void {
    lockPrint();
    defer unlockPrint();
    defer bios.debugFlush();

    var debugStream = DebugStream.init();
    try fmt.format(debugStream.outStream(), formatString, args);
}

pub fn write(message: []const u8) !void {
    lockPrint();
    defer unlockPrint();
    defer bios.debugFlush();

    if (message.len >= AGB_BUFFER_SIZE) {
        for (message[0..AGB_BUFFER_SIZE]) |char| {
            printChar(char);
        }

        return error.BufferTooSmall;
    }

    for (message) |char| {
        printChar(char);
    }
}

inline fn lockPrint() void {
    AGB_PRINT_PROTECT.* = 0x20;
}

inline fn unlockPrint() void {
    AGB_PRINT_PROTECT.* = 0x00;
}

fn printChar(value: u8) void {
    var data: u16 = AGB_PRINT_BUFFER[AGB_PRINT_CONTEXT.put >> 1];

    if ((AGB_PRINT_CONTEXT.put & 1) == 1) {
        data = (@as(u16, @intCast(value)) << 8) | (data & 0xFF);
    } else {
        data = (data & 0xFF00) | value;
    }
    AGB_PRINT_BUFFER[AGB_PRINT_CONTEXT.put >> 1] = data;
    AGB_PRINT_CONTEXT.put += 1;
}
