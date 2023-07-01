const GBA = @import("gba").GBA;
const Input = @import("gba").Input;
const LCD = @import("gba").LCD;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("MODE4FLIP", "AMFE", "00", 0);

const frontImageData = @embedFile("front.agi");
const backImageData = @embedFile("back.agi");
const paletteData = @embedFile("mode4flip.agp");

fn loadImageData() void {
    GBA.memcpy32(GBA.MODE4_FRONT_VRAM, @as([*]align(2) const u8, @ptrCast(@alignCast(frontImageData))), frontImageData.len);
    GBA.memcpy32(GBA.MODE4_BACK_VRAM, @as([*]align(2) const u8, @ptrCast(@alignCast(backImageData))), backImageData.len);
    GBA.memcpy32(GBA.BG_PALETTE_RAM, @as([*]align(2) const u8, @ptrCast(@alignCast(paletteData))), paletteData.len);
}

pub fn main() noreturn {
    LCD.setupDisplayControl(.{
        .mode = .Mode4,
        .backgroundLayer2 = .Show,
    });

    loadImageData();

    var i: u32 = 0;
    while (true) {
        Input.readInput();
        while (Input.isKeyDown(Input.Keys.Start)) {
            Input.readInput();
        }

        LCD.naiveVSync();

        i += 1;
        if (i == 60 * 2) {
            i = 0;
            _ = LCD.pageFlip();
        }
    }
}
