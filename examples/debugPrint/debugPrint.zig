const GBA = @import("gba").GBA;
const Debug = @import("gba").Debug;
const LCD = @import("gba").LCD;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("DEBUGPRINT", "ADPE", "00", 0);

pub fn main() noreturn {
    LCD.setupDisplayControl(.{
        .mode = .Mode3,
        .backgroundLayer2 = .Show,
    });

    Debug.init();

    Debug.write("HELLO DEBUGGER!") catch unreachable;

    const gameName = "DebugPrint";

    var i:u32 = 0;
    while (i < 10) : (i += 1) {
        Debug.print("From {}: {}", .{gameName, i}) catch unreachable;
    }

    while (true) {}
}
