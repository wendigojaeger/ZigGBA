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

pub export fn main() void {
    display.ctrl.* = .{
        .mode = .mode4,
        .bg2 = .enable,
    };

    loadImageData();

    const color_up = Color.rgb(27, 27, 29);
    const button_palette_id = 5;
    const bank0 = &gba.bg.palette.banks[0];

    var frame: u3 = 0;
    while (true) {
        display.naiveVSync();

        if (frame == 0) {
            _ = input.poll();
        }

        for (0..10) |i| {
            const key: input.Key = @enumFromInt(i);
            bank0[button_palette_id + i] = if (input.isKeyJustPressed(key))
                Color.red
            else if (input.isKeyJustReleased(key))
                Color.yellow
            else if (input.isKeyHeld(key))
                Color.lime
            else
                color_up;
        }

        frame +%= 1;
    }
}
