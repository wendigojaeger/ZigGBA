const GBA = @import("gba").GBA;
const Mode3 = @import("gba").Mode3;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("FIRST", "AFSE", "00", 0);

pub fn main() noreturn {
    GBA.setupDisplay(GBA.DisplayMode.Mode3, GBA.DisplayLayers.Background2);

    Mode3.setPixel(120, 80, GBA.toNativeColor(31, 0, 0));
    Mode3.setPixel(136, 80, GBA.toNativeColor(0, 31, 0));
    Mode3.setPixel(120, 96, GBA.toNativeColor(0, 0, 31));

    while (true) {}
}
