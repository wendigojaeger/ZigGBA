const GBA = @import("gba").GBA;
const Input = @import("gba").Input;
const LCD = @import("gba").LCD;
const Background = @import("gba").Background;

extern const brinPal: [256]c_ushort;
extern const brinTiles: [496]c_ushort;
extern const brinMap: [2048]c_ushort;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("TILEDEMO", "ATDE", "00", 0);

fn loadData() void {
    const tileRam = GBA.VRAM;
    const mapRam = @intToPtr([*]volatile u16, @ptrToInt(GBA.VRAM) + (30 * 2048));
    const bgPaletteRam = GBA.BG_PALETTE_RAM;

    var paletteIndex: usize = 0;
    while (paletteIndex < brinPal.len) : (paletteIndex += 1) {
        bgPaletteRam[paletteIndex] = brinPal[paletteIndex];
    }

    var tileIndex: usize = 0;
    while (tileIndex < brinTiles.len) : (tileIndex += 1) {
        tileRam[tileIndex] = brinTiles[tileIndex];
    }

    var mapIndex: usize = 0;
    while (mapIndex < brinMap.len) : (mapIndex += 1) {
        mapRam[mapIndex] = brinMap[mapIndex];
    }
}

pub fn main() noreturn {
    loadData();

    Background.setupBackground(Background.Background0Control, .{
        .characterBaseBlock = 0,
        .screenBaseBlock = 30,
        .paletteMode = .Color16,
        .screenSize = .Text64x32,
    });

    LCD.setupDisplayControl(.{
        .mode = .Mode0,
        .backgroundLayer0 = .Show,
    });

    var x: i32 = 192;
    var y: i32 = 64;

    while (true) {
        LCD.naiveVSync();

        Input.readInput();

        x += Input.getHorizontal();
        y += Input.getVertical();

        Background.Background0Scroll.setPosition(x, y);
    }
}
