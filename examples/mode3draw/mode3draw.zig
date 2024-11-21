const gba = @import("gba");
const Color = gba.Color;
const Mode3 = gba.bitmap.Mode3;
const display = gba.display;

export var header linksection(".gbaheader") = gba.initHeader("MODE3DRAW", "AWJE", "00", 0);

pub export fn main() void {
    display.ctrl.* = .{
        .mode = .mode3,
        .bg2 = .enable,
    };

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

    for (0..9) |i| {
        const m: u8 = @intCast(i);
        const n = 3 * m + 7;
        // Lines in top right frame
        Mode3.line(.{ 132 + 11 * m, 9 }, .{ 226, 12 + 7 * m }, Color.rgb(@intCast(n), 0, @intCast(n)));
        Mode3.line(.{ 226 - 11 * m, 70 }, .{ 133, 69 - 7 * m }, Color.rgb(@intCast(n), 0, @intCast(n)));
        // Lines in bottom left frame
        Mode3.line(.{ 15 + 11 * m, 88 }, .{ 104 - 11 * m, 150 }, Color.rgb(0, @intCast(n), @intCast(n)));
    }
}
