const GBA = @import("gba").GBA;
const Mode3 = @import("gba").Mode3;
const LCD = @import("gba").LCD;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("FIRST", "AFSE", "00", 0);

pub fn main() noreturn {
    LCD.setupDisplayControl(.{
        .mode = .Mode3,
        .backgroundLayer2 = .Show,
    });

    Mode3.setPixel(120, 80, GBA.toNativeColor(31, 0, 0));
    Mode3.setPixel(136, 80, GBA.toNativeColor(0, 31, 0));
    Mode3.setPixel(120, 96, GBA.toNativeColor(0, 0, 31));

    while (true) {}
}
