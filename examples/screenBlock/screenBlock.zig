const gba = @import("gba");
const input = gba.input;
const display = gba.display;
const bg = gba.bg;

export var gameHeader linksection(".gbaheader") = gba.Header.init("SCREENBLOCK", "ASBE", "00", 0);

const CrossTX = 15;
const CrossTY = 10;

fn screenIndex(tx: u32, ty: u32, pitch: u32) u32 {
    const sbb: u32 = ((tx >> 5) + (ty >> 5) * (pitch >> 5));
    return sbb * 1024 + ((tx & 31) + (ty & 31) * 32);
}

fn initMap() void {
    // Init background
    gba.io.bg_ctrl[0] = .{
        .screen_base_block = 28,
        .tile_map_size = .{ .normal = .@"64x64" },
    };
    gba.io.bg_scroll[0].set(0, 0);

    // create the tiles: basic tile and a cross
    bg.tile_memory[0][0] = .{
        .data = [_]u32{ 0x11111111, 0x01111111, 0x01111111, 0x01111111, 0x01111111, 0x01111111, 0x01111111, 0x00000001 },
    };
    bg.tile_memory[0][1] = .{
        .data = [_]u32{ 0x00000000, 0x00100100, 0x01100110, 0x00011000, 0x00011000, 0x01100110, 0x00100100, 0x00000000 },
    };

    // Create the background palette
    bg.palette[0][1] = gba.Color.rgb(31, 0, 0);
    bg.palette[1][1] = gba.Color.rgb(0, 31, 0);
    bg.palette[2][1] = gba.Color.rgb(0, 0, 31);
    bg.palette[3][1] = gba.Color.rgb(16, 16, 16);

    const bg0_map: [*]volatile bg.TextScreenEntry = @ptrCast(&bg.screen_block_memory[28]);

    // Create the map: four contigent blocks of 0x0000, 0x1000, 0x2000, 0x3000
    var paletteIndex: usize = 0;
    var mapIndex: usize = 0;
    while (paletteIndex < 4) : (paletteIndex += 1) {
        var blockCount: usize = 0;
        while (blockCount < 32 * 32) : ({
            blockCount += 1;
            mapIndex += 1;
        }) {
            bg0_map[mapIndex].palette_idx = @intCast(paletteIndex);
        }
    }
}

pub fn main() noreturn {
    initMap();
    gba.io.display_ctrl.show = .{
        .bg0 = true,
        .obj_layer = true,
    };

    var x: i32 = 0;
    var y: i32 = 0;
    var tx: u32 = 0;
    var ty: u32 = 0;
    var screenBlockCurrent: usize = 0;
    var screenBlockPrevious: usize = CrossTY * 32 + CrossTX;

    const bg0_map = @as([*]volatile bg.TextScreenEntry, @ptrCast(&bg.screen_block_memory[28]));
    bg0_map[screenBlockPrevious].tile_idx += 1;

    while (true) {
        display.naiveVSync();

        _ = input.poll();

        x += input.Axis.get(.Horizontal);
        y += input.Axis.get(.Vertical);

        tx = ((@as(u32, @bitCast(x)) >> 3) + CrossTX) & 0x3F;
        ty = ((@as(u32, @bitCast(y)) >> 3) + CrossTY) & 0x3F;

        screenBlockCurrent = screenIndex(tx, ty, 64);

        if (screenBlockPrevious != screenBlockCurrent) {
            bg0_map[screenBlockPrevious].tile_idx -= 1;
            bg0_map[screenBlockCurrent].tile_idx += 1;
            screenBlockPrevious = screenBlockCurrent;
        }

        gba.io.bg_scroll[0].set(@truncate(x), @truncate(y));
    }
}
