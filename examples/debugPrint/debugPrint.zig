const GBA = @import("gba").GBA;
const Debug = @import("gba").Debug;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("DEBUGPRINT", "ADPE", "00", 0);

pub fn main() noreturn {
    GBA.setupDisplay(GBA.DisplayMode.Mode3, GBA.DisplayLayers.Background2);

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
