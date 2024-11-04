const gba = @import("gba");
const gba_pic = @import("gba_pic.zig");
const Color = gba.Color;
const input = gba.input;
const display = gba.display;

export var gameHeader linksection(".gbaheader") = gba.Header.init("KEYDEMO", "AKDE", "00", 0);

fn loadImageData() void {
    gba.memcpy32(gba.MODE4_FRONT_VRAM, &gba_pic.bitmap, gba_pic.bitmap.len * 4);
    gba.memcpy32(gba.bg.palette, &gba_pic.pal, gba_pic.pal.len * 4);
}

pub fn main() noreturn {
    gba.io.display_ctrl.* = .{
        .mode = .mode4,
        .show = .{ .bg2 = true },
    };

    loadImageData();

    const ColorUp = gba.Color.rgb(27, 27, 29);
    const ButtonPaletteId = 5;

    var frame: u32 = 0;
    while (true) {
        display.naiveVSync();

        if ((frame & 7) == 0) {
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
                ColorUp;

            gba.bg.palette[0][ButtonPaletteId + i] = color;
        }

        frame += 1;
    }
}
