const GBA = @import("gba").GBA;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("FIRST", "AFSE", "00", 0);

pub fn main() noreturn {
    GBA.setupDisplay(GBA.DisplayMode.Mode3, GBA.DisplayLayers.Background2 | GBA.DisplayLayers.Background0);

    GBA.mode3SetPixel(120, 80, GBA.toNativeColor(31, 0, 0));
    GBA.mode3SetPixel(136, 80, GBA.toNativeColor(0, 31, 0));
    GBA.mode3SetPixel(120, 96, GBA.toNativeColor(0, 0, 31));

    while (true) {}
}
