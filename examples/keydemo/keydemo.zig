const gba = @import("gba");
const gba_pic = @import("gba_pic.zig");
const Color = gba.Color;
const input = gba.input;
const display = gba.display;

export var header linksection(".gbaheader") = gba.initHeader("KEYDEMO", "AKDE", "00", 0);

fn loadImageData() void {
    gba.mem.memcpy32(gba.display.vram, &gba_pic.bitmap, gba_pic.bitmap.len * 4);
    gba.mem.memcpy32(gba.bg.palette, &gba_pic.pal, gba_pic.pal.len * 4);
}

pub fn main() void {
    display.ctrl.* = .{
        .mode = .mode4,
        .show = .{ .bg2 = true },
    };

    loadImageData();

    const color_up = Color.rgb(27, 27, 29);
    const button_palette_id = 5;

    var frame: u3 = 0;
    while (true) {
        display.naiveVSync();

        if (frame == 0) {
            _ = input.poll();
        }

        for (0..10) |i| {
            const key: input.Key = @enumFromInt(i);
            const color = if (input.isKeyJustPressed(key))
                Color.red
            else if (input.isKeyJustReleased(key))
                Color.yellow
            else if (input.isKeyHeld(key))
                Color.lime
            else
                color_up;

            gba.bg.palette.banks[0][button_palette_id + i] = color;
        }

        frame +%= 1;
    }
}
