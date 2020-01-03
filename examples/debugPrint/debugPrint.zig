const GBA = @import("gba").GBA;
const Debug = @import("gba").Debug;
const LCD = @import("gba").LCD;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("DEBUGPRINT", "ADPE", "00", 0);

pub fn main() noreturn {
    LCD.setupDisplay(LCD.DisplayMode.Mode3, LCD.DisplayLayers.Background2);

    Debug.init();

    Debug.write("HELLO DEBUGGER!") catch unreachable;

    // TODO: requires __clzsi2 in compiler-rt
    // const gameName = "DebugPrint";

    // var i:u32 = 0;
    // while (i < 10) : (i += 1) {
    //     Debug.print("From {}: {}", .{gameName, i}) catch unreachable;
    // }

    while (true) {}
}
