const gba = @import("gba");
const Color = gba.Color;
const Mode3 = gba.bitmap.Mode3;

export var header linksection(".gbaheader") = gba.initHeader("FIRST", "AFSE", "00", 0);

pub export fn main() void {
    gba.display.ctrl.* = .{
        .mode = .mode3,
        .bg2 = .enable,
    };

    Mode3.setPixel(120, 80, Color.rgb(31, 0, 0));
    Mode3.setPixel(136, 80, Color.rgb(0, 31, 0));
    Mode3.setPixel(120, 96, Color.rgb(0, 0, 31));
}
