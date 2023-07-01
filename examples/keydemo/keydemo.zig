const GBA = @import("gba").GBA;
const Color = @import("gba").Color;
const Input = @import("gba").Input;
const LCD = @import("gba").LCD;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("KEYDEMO", "AKDE", "00", 0);

extern const gba_picPal: [8]c_uint;
extern const gba_picBitmap: [9600]c_uint;

fn loadImageData() void {
    GBA.memcpy32(GBA.MODE4_FRONT_VRAM, &gba_picBitmap, gba_picBitmap.len * 4);
    GBA.memcpy32(GBA.BG_PALETTE_RAM, &gba_picPal, gba_picPal.len * 4);
}

pub fn main() noreturn {
    LCD.setupDisplayControl(.{
        .mode = .Mode4,
        .backgroundLayer2 = .Show,
    });

    loadImageData();

    const ColorUp = GBA.toNativeColor(27, 27, 29);
    const ButtonPaletteId = 5;

    var color: u16 = 0;

    var frame: u32 = 0;
    while (true) {
        LCD.naiveVSync();

        if ((frame & 7) == 0) {
            Input.readInput();
        }

        var keyIndex: usize = 0;
        while (keyIndex < @intFromEnum(Input.KeyIndex.Count)) : (keyIndex += 1) {
            color = 0;
            const key = @as(u16, 1) << @intCast(keyIndex);

            if (Input.isKeyJustPressed(key)) {
                color = Color.Red;
            } else if (Input.isKeyJustReleased(key)) {
                color = Color.Yellow;
            } else if (Input.isKeyHeld(key)) {
                color = Color.Lime;
            } else {
                color = ColorUp;
            }

            GBA.BG_PALETTE_RAM[ButtonPaletteId + keyIndex] = color;
        }

        frame += 1;
    }
}
