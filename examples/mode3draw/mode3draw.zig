const GBA = @import("gba").GBA;
const Color = @import("gba").Color;
const Mode3 = @import("gba").Mode3;
const LCD = @import("gba").LCD;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("MODE3DRAW", "AWJE", "00", 0);

pub fn main() noreturn {
    LCD.setupDisplayControl(.{
        .mode = .Mode3,
        .backgroundLayer2 = .Show,
    });

    var i: i32 = 0;
    var j: i32 = 0;

    // Fill screen with grey color
    Mode3.fill(GBA.toNativeColor(12, 12, 12));

    // Rectangles:
    Mode3.rect(12, 8, 109, 72, Color.Red);
    Mode3.rect(108, 72, 132, 88, Color.Lime);
    Mode3.rect(132, 88, 228, 152, Color.Blue);

    // Rectangle frames
    Mode3.frame(132, 8, 228, 72, Color.Cyan);
    Mode3.frame(109, 73, 131, 87, Color.Black);
    Mode3.frame(12, 88, 108, 152, Color.Yellow);

    // Lines in top right frame
    while (i <= 8) : (i += 1) {
        j = 3 * i + 7;
        Mode3.line(132 + 11 * i, 9, 226, 12 + 7 * i, GBA.toNativeColor(@intCast(j), 0, @intCast(j)));
        Mode3.line(226 - 11 * i, 70, 133, 69 - 7 * i, GBA.toNativeColor(@intCast(j), 0, @intCast(j)));
    }

    // Lines in bottom left frame
    i = 0;
    while (i <= 8) : (i += 1) {
        j = 3 * i + 7;
        Mode3.line(15 + 11 * i, 88, 104 - 11 * i, 150, GBA.toNativeColor(0, @intCast(j), @intCast(j)));
    }

    while (true) {}
}
