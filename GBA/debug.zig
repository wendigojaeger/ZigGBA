const fmt = @import("std").fmt;
const io = @import("std").io;

const BIOS = @import("bios.zig").BIOS;

pub const Debug = struct {
    const PrintContext = packed struct {
        request: u16,
        bank: u16,
        get: u16,
        put: u16,
    };

    const DebugStream = struct {
        streamWritten: usize,

        const Self = @This();

        pub fn init() Self {
            return Self{
                .streamWritten = 0,
            };
        }

        pub fn write(self: *Self, bytes: []const u8) !usize {
            const remaining = AGB_BUFFER_SIZE - self.streamWritten;
            if (remaining < bytes.len) {
                var index: usize = 0;
                while (index < remaining) : (index += 1) {
                    printChar(bytes[index]);
                }
                return error.BufferTooSmall;
            }

            var written: usize = 0;
            for (bytes) |char| {
                printChar(char);
                self.streamWritten += 1;
                written += 1;
            }

            return written;
        }

        pub fn outStream(self: *Self) io.Writer(*Self, error{BufferTooSmall}, Self.write) {
            return .{ .context = self };
        }
    };

    const AGB_PRINT_PROTECT = @as(*volatile u16, @ptrFromInt(0x09FE2FFE));
    const AGB_PRINT_CONTEXT = @as(*volatile PrintContext, @ptrFromInt(0x09FE20F8));
    const AGB_PRINT_BUFFER = @as([*]volatile u16, @ptrFromInt(0x09FD0000));
    const AGB_BUFFER_SIZE = 0x100;

    pub fn init() void {
        AGB_PRINT_PROTECT.* = 0x20;
        AGB_PRINT_CONTEXT.request = 0x00;
        AGB_PRINT_CONTEXT.get = 0x00;
        AGB_PRINT_CONTEXT.put = 0x00;
        AGB_PRINT_CONTEXT.bank = 0xFD;
        AGB_PRINT_PROTECT.* = 0x00;
    }

    pub fn print(comptime formatString: []const u8, args: anytype) !void {
        lockPrint();
        defer unlockPrint();
        defer BIOS.debugFlush();

        var debugStream = DebugStream.init();
        try fmt.format(debugStream.outStream(), formatString, args);
    }

    pub fn write(message: []const u8) !void {
        lockPrint();
        defer unlockPrint();
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
};
