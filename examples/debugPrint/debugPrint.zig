const gba = @import("gba");
const debug = gba.debug;
const display = gba.display;

export var header linksection(".gbaheader") = gba.initHeader("DEBUGPRINT", "ADPE", "00", 0);

pub fn main() void {
    display.ctrl.* = .{
        .mode = .mode3,
        .show = .{ .bg2 = false },
    };

    debug.init();

    debug.write("HELLO DEBUGGER!") catch {};

    const game_name = "DebugPrint";

    for (0..10) |i| {
        debug.print("From {s}: {d}", .{ game_name, i }) catch {};
    }
}
