const gba = @import("gba");
const Color = gba.Color;
const Mode3 = gba.Bitmap(Color, 240, 160);
const display = gba.display;

export var gameHeader linksection(".gbaheader") = gba.Header.init("MODE3DRAW", "AWJE", "00", 0);

pub export fn main() noreturn {
    gba.io.display_ctrl.* = .{
        .mode = .mode3,
        .show = .{ .bg2 = true },
    };

    var i: u8 = 0;
    var j: u8 = 0;

    // Fill screen with grey color
    Mode3.fill(Color.rgb(12, 12, 12));

    // Rectangles:
    Mode3.rect(.{ 12, 8 }, .{ 109, 72 }, Color.red);
    Mode3.rect(.{ 108, 72 }, .{ 132, 88 }, Color.lime);
    Mode3.rect(.{ 132, 88 }, .{ 228, 152 }, Color.blue);

    // Rectangle frames
    Mode3.frame(.{ 132, 8 }, .{ 228, 72 }, Color.cyan);
    Mode3.frame(.{ 109, 73 }, .{ 131, 87 }, Color.black);
    Mode3.frame(.{ 12, 88 }, .{ 108, 152 }, Color.yellow);

    // Lines in top right frame
    while (i <= 8) : (i += 1) {
        j = 3 * i + 7;
        Mode3.line(.{ 132 + 11 * i, 9 }, .{ 226, 12 + 7 * i }, Color.rgb(@intCast(j), 0, @intCast(j)));
        Mode3.line(.{ 226 - 11 * i, 70 }, .{ 133, 69 - 7 * i }, Color.rgb(@intCast(j), 0, @intCast(j)));
    }

    // Lines in bottom left frame
    i = 0;
    while (i <= 8) : (i += 1) {
        j = 3 * i + 7;
        Mode3.line(.{ 15 + 11 * i, 88 }, .{ 104 - 11 * i, 150 }, Color.rgb(0, @intCast(j), @intCast(j)));
    }

    while (true) {}
}
