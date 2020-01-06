const GBA = @import("gba").GBA;
const Input = @import("gba").Input;
const LCD = @import("gba").LCD;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("MODE4FLIP", "AMFE", "00", 0);

// FIXME: somehow export align the const data properly
export const frontImageData = @embedFile("front.agi");
export const backImageData = @embedFile("back.agi");
export const paletteData = @embedFile("mode4flip.agp");

fn loadImageData() void {
    GBA.memcpy32(GBA.MODE4_FRONT_VRAM, @ptrCast([*] const u8, frontImageData), frontImageData.len);
    GBA.memcpy32(GBA.MODE4_BACK_VRAM, @ptrCast([*] const u8, backImageData), backImageData.len);
    GBA.memcpy32(GBA.BG_PALETTE_RAM, @ptrCast([*] const u8, paletteData), paletteData.len);
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
