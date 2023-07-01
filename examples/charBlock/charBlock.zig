const GBA = @import("gba").GBA;
const Input = @import("gba").Input;
const LCD = @import("gba").LCD;
const Background = @import("gba").Background;

extern const ids8Tiles: [144]c_uint;
extern const ids4Pal: [8]c_uint;
extern const ids4Tiles: [40]c_uint;

const CharacterBlock4 = 0;
const ScreenBlock4 = 2;

const CharacterBlock8 = 2;
const ScreenBlock8 = 4;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("CHARBLOCK", "ASBE", "00", 0);

fn loadTiles() void {
    const tl: [*]align(4) Background.Tile = @ptrFromInt(@intFromPtr(&ids4Tiles[0]));
    const tl8: [*]align(4) Background.Tile8 = @ptrFromInt(@intFromPtr(&ids8Tiles[0]));

    // Loading tiles. 4-bit tiles to blocks 0 and 1
    Background.TileMemory[0][1] = tl[1];
    Background.TileMemory[0][2] = tl[2];
    Background.TileMemory[1][0] = tl[3];
    Background.TileMemory[1][1] = tl[4];

    // and the 8-bit tiles to blocks 2 though 5
    Background.Tile8Memory[2][1] = tl8[1];
    Background.Tile8Memory[2][2] = tl8[2];
    Background.Tile8Memory[3][0] = tl8[3];
    Background.Tile8Memory[3][1] = tl8[4];
    Background.Tile8Memory[4][0] = tl8[5];
    Background.Tile8Memory[4][1] = tl8[6];
    Background.Tile8Memory[5][0] = tl8[7];
    Background.Tile8Memory[5][1] = tl8[8];

    // Load palette
    GBA.memcpy32(GBA.BG_PALETTE_RAM, &ids4Pal, ids4Pal.len * @sizeOf(c_uint));
    GBA.memcpy32(GBA.OBJ_PALETTE_RAM, &ids4Pal, ids4Pal.len * @sizeOf(c_uint));
}

fn initMaps() void {
    // map coords (0,2)
    const screenEntry4_ptr: ?[*]Background.TextScreenEntry = @ptrFromInt(@intFromPtr(&Background.ScreenBlockMemory[ScreenBlock4][2 * 32]));
    // map coords (0, 8)
    const screenEntry8_ptr: ?[*]Background.TextScreenEntry = @ptrFromInt(@intFromPtr(&Background.ScreenBlockMemory[ScreenBlock8][8 * 32]));

    if (screenEntry4_ptr) |screenEntry4| {
        // Show first tiles of char-blocks available to background 0
        // tiles 1, 2 of CharacterBlock4
        screenEntry4[0x01].tileIndex = 0x0001;
        screenEntry4[0x02].tileIndex = 0x0002;
        // tiles 0, 1 of CharacterBlock4+1
        screenEntry4[0x20].tileIndex = 0x0200;
        screenEntry4[0x21].tileIndex = 0x0201;
    }

    if (screenEntry8_ptr) |screenEntry8| {
        // Show first tiles of char-blocks available to background 1
        // tiles 1, 2 of CharacterBlock8 (== 2)
        screenEntry8[0x01].tileIndex = 0x0001;
        screenEntry8[0x02].tileIndex = 0x0002;

        // tiles 1, 2 of CharacterBlock8+1
        screenEntry8[0x20].tileIndex = 0x0100;
        screenEntry8[0x21].tileIndex = 0x0101;

        // tiles 1, 2 of char-block CharacterBlock8+2 (== CBB_OBJ_LO)
        screenEntry8[0x40].tileIndex = 0x0200;
        screenEntry8[0x41].tileIndex = 0x0201;

        // tiles 1, 2 of char-block CharacterBlock8+3 (== CBB_OBJ_HI)
        screenEntry8[0x60].tileIndex = 0x0300;
        screenEntry8[0x61].tileIndex = 0x0301;
    }
}

pub fn main() noreturn {
    loadTiles();

    initMaps();

    LCD.setupDisplayControl(.{
        .mode = .Mode0,
        .backgroundLayer0 = .Show,
        .backgroundLayer1 = .Show,
        .objectLayer = .Show,
    });

    Background.setupBackground(Background.Background0Control, .{
        .characterBaseBlock = CharacterBlock4,
        .screenBaseBlock = ScreenBlock4,
        .paletteMode = .Color16,
    });

    Background.setupBackground(Background.Background1Control, .{
        .characterBaseBlock = CharacterBlock8,
        .screenBaseBlock = ScreenBlock8,
        .paletteMode = .Color256,
    });

    while (true) {}
}
