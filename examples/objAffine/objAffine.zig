const GBA = @import("gba").GBA;
const Input = @import("gba").Input;
const LCD = @import("gba").LCD;
const OAM = @import("gba").OAM;
const Debug = @import("gba").Debug;
const Math = @import("gba").Math;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("OBJAFFINE", "AODE", "00", 0);

extern const metrPal: [16]c_uint;
extern const metrTiles: [512]c_uint;
extern const metr_boxTiles: [512]c_uint;

pub fn main() noreturn {
    LCD.setupDisplayControl(.{
        .objVramCharacterMapping = .OneDimension,
        .objectLayer = .Show,
        .backgroundLayer0 = .Show,
    });

    Debug.init();
    OAM.init();

    GBA.memcpy32(GBA.SPRITE_VRAM, &metr_boxTiles, metr_boxTiles.len * 4);
    GBA.memcpy32(GBA.OBJ_PALETTE_RAM, &metrPal, metrPal.len * 4);

    const metroid = OAM.allocate();
    metroid.setRotationParameterIndex(0);
    metroid.setSize(.Size64x64);
    metroid.rotationScaling = true;
    metroid.palette = 0;
    metroid.tileIndex = 0;
    metroid.setPosition(96, 32);
    metroid.getAffine().setIdentity();

    const shadow_metroid = OAM.allocate();
    shadow_metroid.setRotationParameterIndex(31);
    shadow_metroid.setSize(.Size64x64);
    shadow_metroid.rotationScaling = true;
    shadow_metroid.palette = 1;
    shadow_metroid.tileIndex = 0;
    shadow_metroid.setPosition(96, 32);
    shadow_metroid.getAffine().setIdentity();

    OAM.update(2);

    while (true) {
        LCD.naiveVSync();

        Input.readInput();
    }
}
