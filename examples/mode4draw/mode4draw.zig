const gba = @import("gba");
const Color = gba.Color;
const Mode4 = display.Mode4;
const display = gba.display;

export var gameHeader linksection(".gbaheader") = gba.Header.init("MODE4DRAW", "AWJE", "00", 0);

const palette: [26]Color = [_]Color{
    Color.black,
    Color.rgb(12, 12, 12),
    Color.red,
    Color.lime,
    Color.blue,
    Color.cyan,
    Color.black,
    Color.yellow,
} ++ blk: {
    var pink: [9]Color = undefined;
    var teal: [9]Color = undefined;

    for (0..9) |i| {
        const j = @as(u5, @intCast(i)) * 3 + 7;
        pink[i] = Color.rgb(j, 0, j);
        teal[i] = Color.rgb(0, j, j);
    }

    break :blk pink ++ teal;
};

pub export fn main() noreturn {
    gba.memcpy32(gba.bg.palette, &palette, 256);

    gba.io.display_ctrl.* = .{
        .mode = .mode4,
        .show = .{ .bg2 = true },
    };

    // Fill screen with grey color
    Mode4.fill(1);

    // Rectangles:
    Mode4.rect(.{ 12, 8 }, .{ 109, 72 }, 2);
    Mode4.rect(.{ 108, 72 }, .{ 132, 88 }, 3);
    Mode4.rect(.{ 132, 88 }, .{ 228, 152 }, 4);

    // Rectangle frames
    Mode4.frame(.{ 132, 8 }, .{ 228, 72 }, 5);
    Mode4.frame(.{ 109, 73 }, .{ 131, 87 }, 6);
    Mode4.frame(.{ 12, 88 }, .{ 108, 152 }, 7);

    for (0..9) |j| {
        const i: u8 = @intCast(j);
        // Lines in top right frame
        Mode4.line(.{ 132 + 11 * i, 9 }, .{ 226, 12 + 7 * i }, 8 + i);
        Mode4.line(.{ 226 - 11 * i, 70 }, .{ 133, 69 - 7 * i }, 8 + i);
        // Lines in bottom left frame
        Mode4.line(.{ 15 + 11 * i, 88 }, .{ 104 - 11 * i, 150 }, 17 + i);
    }

    while (true) {}
}
