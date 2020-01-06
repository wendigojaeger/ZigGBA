const GBA = @import("gba").GBA;
const Input = @import("gba").Input;
const LCD = @import("gba").LCD;
const OAM = @import("gba").OAM;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("OBJDEMO", "AODE", "00", 0);

extern const metrPal: [16]c_uint;
extern const metrTiles: [512]c_uint;

fn loadSpriteData() void {
    const spriteVram = @ptrCast([*]volatile u32, GBA.SPRITE_VRAM);
    const objPaletteRam = @ptrCast([*]volatile u32, GBA.OBJ_PALETTE_RAM);

    var tileIndex: usize = 0;
    while (tileIndex < metrTiles.len) : (tileIndex += 1) {
        spriteVram[tileIndex] = metrTiles[tileIndex];
    }

    var paletteIndex: usize = 0;
    while (paletteIndex < metrPal.len) : (paletteIndex += 1) {
        objPaletteRam[paletteIndex] = metrPal[paletteIndex];
    }
}

pub fn main() noreturn {
    LCD.setupDisplayControl(.{
        .objVramCharacterMapping = .OneDimension,
        .objectLayer = .Show,
    });

    OAM.init();

    loadSpriteData();

    var metroid: *OAM.Attribute = OAM.allocate();
    metroid.x = 100;
    metroid.y = 150;
    metroid.palette = 0;
    metroid.tileIndex = 0;
    metroid.setSize(.Size64x64);

    var x: i32 = 96;
    var y: i32 = 32;
    var tileIndex: i32 = 0;

    while (true) {
        LCD.naiveVSync();

        Input.readInput();

        x += Input.getHorizontal() * 2;
        y += Input.getVertical() * 2;

        tileIndex += Input.getShoulderJustPressed();

        if (Input.isKeyJustPressed(Input.Keys.A)) {
            metroid.flip.horizontalFlip = ~metroid.flip.horizontalFlip;
        }
        if (Input.isKeyJustPressed(Input.Keys.B)) {
            metroid.flip.verticalFlip = ~metroid.flip.verticalFlip;
        }

        metroid.palette = if (Input.isKeyDown(Input.Keys.Select)) 1 else 0;

        LCD.changeObjVramCharacterMapping(if (Input.isKeyDown(Input.Keys.Start)) .TwoDimension else .OneDimension);

        metroid.setPosition(x, y);
        metroid.setTileIndex(tileIndex);

        OAM.update(1);
    }
}
