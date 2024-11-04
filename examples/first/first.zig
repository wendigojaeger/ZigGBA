const gba = @import("gba");
const io = gba.io;
const display = gba.display;
const Mode3 = display.Mode.mode3.bitmap().?;
const Color = gba.Color;

export var gameHeader linksection(".gbaheader") = gba.Header.init("FIRST", "AFSE", "00", 0);

pub fn main() noreturn {
    io.display_ctrl.* = .{
        .mode = .mode3,
        .show = .{ .bg2 = true },
    };

    Mode3.setPixel(120, 80, .{ .r = 31, .g = 0, .b = 0 });
    Mode3.setPixel(136, 80, Color.rgb(0, 31, 0));
    Mode3.setPixel(120, 96, Color.rgb(0, 0, 31));

    while (true) {}
}
