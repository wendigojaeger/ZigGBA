const GBA = @import("gba").GBA;
const Input = @import("gba").Input;
const LCD = @import("gba").LCD;
const Background = @import("gba").Background;

extern const brinPal: [256]c_ushort;
extern const brinTiles: [496]c_ushort;
extern const brinMap: [2048]c_ushort;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("TILEDEMO", "ATDE", "00", 0);

fn loadData() void {
    const mapRam = @intToPtr([*]volatile u16, @ptrToInt(GBA.VRAM) + (30 * 2048));

    GBA.memcpy32(GBA.BG_PALETTE_RAM, &brinPal, brinPal.len * 2);
    GBA.memcpy32(GBA.VRAM, &brinTiles, brinTiles.len * 2);
    GBA.memcpy32(mapRam, &brinMap, brinMap.len * 2);
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
