const GBA = @import("gba").GBA;
const Input = @import("gba").Input;
const LCD = @import("gba").LCD;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("MODE4FLIP", "AMFE", "00", 0);

const frontImageData = @embedFile("front.agi");
const backImageData = @embedFile("back.agi");
const paletteData = @embedFile("mode4flip.agp");

fn loadImageData() void {
    const frontImage = @ptrCast([*]const u32, frontImageData);
    const backImage = @ptrCast([*]const u32, backImageData);
    const vramFront = @ptrCast([*]volatile u32, GBA.MODE4_FRONT_VRAM);
    const vramBack = @ptrCast([*]volatile u32, GBA.MODE4_BACK_VRAM);
    const bgPaletteRam = @ptrCast([*]volatile u32, GBA.BG_PALETTE_RAM);
    const palette = @ptrCast([*]const u32, paletteData);

    const frontEnd = comptime (frontImageData.len / 4);
    const backEnd = comptime (backImageData.len / 4);
    const paletteEnd = comptime (paletteData.len / 4);

    // FIXME: the front buffer is glichy in Debug
    var frontIndex: usize = 0;
    while (frontIndex < frontEnd) : (frontIndex += 1) {
        vramFront[frontIndex] = frontImage[frontIndex];
    }

    var backIndex: usize = 0;
    while (backIndex < backEnd) : (backIndex += 1) {
        vramBack[backIndex] = backImage[backIndex];
    }

    var paletteIndex: usize = 0;
    while (paletteIndex < paletteEnd) : (paletteIndex += 1) {
        bgPaletteRam[paletteIndex] = palette[paletteIndex];
    }
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
