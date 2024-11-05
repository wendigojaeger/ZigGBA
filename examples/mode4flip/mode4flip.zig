const gba = @import("gba");
const input = gba.input;
const display = gba.display;

export var gameHeader linksection(".gbaheader") = gba.Header.init("MODE4FLIP", "AMFE", "00", 0);

const frontImageData = @embedFile("front.agi");
const backImageData = @embedFile("back.agi");
const paletteData = @embedFile("mode4flip.agp");

fn loadImageData() void {
    gba.memcpy32(gba.MODE4_FRONT_VRAM, @as([*]align(2) const u8, @ptrCast(@alignCast(frontImageData))), frontImageData.len);
    gba.memcpy32(gba.MODE4_BACK_VRAM, @as([*]align(2) const u8, @ptrCast(@alignCast(backImageData))), backImageData.len);
    gba.memcpy32(gba.bg.palette, @as([*]align(2) const u8, @ptrCast(@alignCast(paletteData))), paletteData.len);
}

pub fn main() noreturn {
    gba.io.display_ctrl.* = .{};
    gba.io.display_ctrl.mode = .mode4;
    gba.io.display_ctrl.show.bg2 = true;

    loadImageData();

    var i: u32 = 0;
    while (true) : (i += 1) {
        _ = input.poll();
        while (input.isKeyPressed(.Start)) {
            _ = input.poll();
        }

        display.naiveVSync();

        if (i == 60 * 2) {
            i = 0;
            display.pageFlip();
        }
    }
}
