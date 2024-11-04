const gba = @import("gba");
const debug = gba.debug;
const display = gba.display;

export var gameHeader linksection(".gbaheader") = gba.Header.init("DEBUGPRINT", "ADPE", "00", 0);

pub export fn main() noreturn {
    gba.io.display_ctrl.* = .{
        .mode = .mode3,
        .show = .{ .bg2 = false },
    };

    debug.init();

    debug.write("HELLO DEBUGGER!") catch unreachable;

    const gameName = "DebugPrint";

    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        debug.print("From {s}: {}", .{ gameName, i }) catch unreachable;
    }

    while (true) {}
}
