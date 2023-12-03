const GBA = @import("gba").GBA;
const Input = @import("gba").Input;
const LCD = @import("gba").LCD;
const Background = @import("gba").Background;

export var gameHeader linksection(".gbaheader") = GBA.Header.setup("SCREENBLOCK", "ASBE", "00", 0);

const CrossTX = 15;
const CrossTY = 10;

fn screenIndex(tx: u32, ty: u32, pitch: u32) u32 {
    const sbb: u32 = ((tx >> 5) + (ty >> 5) * (pitch >> 5));
    return sbb * 1024 + ((tx & 31) + (ty & 31) * 32);
}

fn initMap() void {
    // Init background
    Background.setupBackground(Background.Background0Control, .{
        .characterBaseBlock = 0,
        .screenBaseBlock = 28,
        .paletteMode = .Color16,
        .screenSize = .Text64x64,
    });
    Background.Background0Scroll.setPosition(0, 0);

    // create the tiles: basic tile and a cross
    Background.TileMemory[0][0] = .{
        .data = [_]u32{ 0x11111111, 0x01111111, 0x01111111, 0x01111111, 0x01111111, 0x01111111, 0x01111111, 0x00000001 },
    };
    Background.TileMemory[0][1] = .{
        .data = [_]u32{ 0x00000000, 0x00100100, 0x01100110, 0x00011000, 0x00011000, 0x01100110, 0x00100100, 0x00000000 },
    };

    // Create the background palette
    Background.Palette[0][1] = GBA.toNativeColor(31, 0, 0);
    Background.Palette[1][1] = GBA.toNativeColor(0, 31, 0);
    Background.Palette[2][1] = GBA.toNativeColor(0, 0, 31);
    Background.Palette[3][1] = GBA.toNativeColor(16, 16, 16);

    const bg0_map: [*]volatile Background.TextScreenEntry = @ptrCast(&Background.ScreenBlockMemory[28]);

    // Create the map: four contigent blocks of 0x0000, 0x1000, 0x2000, 0x3000
    var paletteIndex: usize = 0;
    var mapIndex: usize = 0;
    while (paletteIndex < 4) : (paletteIndex += 1) {
        var blockCount: usize = 0;
        while (blockCount < 32 * 32) : ({
            blockCount += 1;
            mapIndex += 1;
        }) {
            bg0_map[mapIndex].paletteIndex = @intCast(paletteIndex);
        }
    }
}

pub fn main() noreturn {
    initMap();

    LCD.setupDisplayControl(.{
        .mode = .Mode0,
        .backgroundLayer0 = .Show,
        .objectLayer = .Show,
    });

    var x: i32 = 0;
    var y: i32 = 0;
    var tx: u32 = 0;
    var ty: u32 = 0;
    var screenBlockCurrent: usize = 0;
    var screenBlockPrevious: usize = CrossTY * 32 + CrossTX;

    const bg0_map = @as([*]volatile Background.TextScreenEntry, @ptrCast(&Background.ScreenBlockMemory[28]));
    bg0_map[screenBlockPrevious].tileIndex += 1;

    while (true) {
        LCD.naiveVSync();

        Input.readInput();

        x += Input.getHorizontal();
        y += Input.getVertical();

        tx = ((@as(u32, @bitCast(x)) >> 3) + CrossTX) & 0x3F;
        ty = ((@as(u32, @bitCast(y)) >> 3) + CrossTY) & 0x3F;

        screenBlockCurrent = screenIndex(tx, ty, 64);

        if (screenBlockPrevious != screenBlockCurrent) {
            bg0_map[screenBlockPrevious].tileIndex -= 1;
            bg0_map[screenBlockCurrent].tileIndex += 1;
            screenBlockPrevious = screenBlockCurrent;
        }

        Background.Background0Scroll.setPosition(x, y);
    }
}
