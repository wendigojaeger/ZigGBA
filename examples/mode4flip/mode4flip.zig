const gba = @import("gba");
const input = gba.input;
const display = gba.display;

export var header linksection(".gbaheader") = gba.initHeader("MODE4FLIP", "AMFE", "00", 0);

const front_image_data = @embedFile("front.agi");
const back_image_data = @embedFile("back.agi");
const palette_data = @embedFile("mode4flip.agp");

fn loadImageData() void {
    gba.mem.memcpy32(display.vram, @as([*]align(2) const u8, @ptrCast(@alignCast(front_image_data))), front_image_data.len);
    gba.mem.memcpy32(display.back_page, @as([*]align(2) const u8, @ptrCast(@alignCast(back_image_data))), back_image_data.len);
    gba.mem.memcpy32(gba.bg.palette, @as([*]align(2) const u8, @ptrCast(@alignCast(palette_data))), palette_data.len);
}

pub fn main() void {
    display.ctrl.* = .{
        .mode = .mode4,
        .bg2 = .enable,
    };

    loadImageData();

    var i: u32 = 0;
    while (true) : (i += 1) {
        _ = input.poll();
        while (input.isKeyPressed(.start)) {
            _ = input.poll();
        }

        display.naiveVSync();

        if (i == 60 * 2) {
            i = 0;
            display.pageFlip();
        }
    }
}
