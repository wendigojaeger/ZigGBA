const gba = @import("gba");
const input = gba.input;
const display = gba.display;
const bg = gba.bg;

export var gameHeader linksection(".gbaheader") = gba.initHeader("SCREENBLOCK", "ASBE", "00", 0);

const cross_tx = 15;
const cross_ty = 10;

fn screenIndex(tx: u32, ty: u32, pitch: u32) u32 {
    const sbb: u32 = ((tx >> 5) + (ty >> 5) * (pitch >> 5));
    return sbb * 1024 + ((tx & 31) + (ty & 31) * 32);
}

fn initMap() void {
    // Init background
    bg.ctrl[0] = .{
        .screen_base_block = 28,
        .tile_map_size = .{ .normal = .@"64x64" },
    };
    bg.scroll[0].set(0, 0);

    // create the tiles: basic tile and a cross
    bg.tile_ram[0][0] = @bitCast([_]u32{ 0x11111111, 0x01111111, 0x01111111, 0x01111111, 0x01111111, 0x01111111, 0x01111111, 0x00000001 });
    bg.tile_ram[0][1] = @bitCast([_]u32{ 0x00000000, 0x00100100, 0x01100110, 0x00011000, 0x00011000, 0x01100110, 0x00100100, 0x00000000 });

    const bg_palette = &bg.palette.banks;

    // Create the background palette
    bg_palette[0][1] = gba.Color.rgb(31, 0, 0);
    bg_palette[1][1] = gba.Color.rgb(0, 31, 0);
    bg_palette[2][1] = gba.Color.rgb(0, 0, 31);
    bg_palette[3][1] = gba.Color.rgb(16, 16, 16);

    const bg0_map: [*]volatile bg.TextScreenEntry = @ptrCast(&bg.screen_block_ram[28]);

    // Create the map: four contigent blocks of 0x0000, 0x1000, 0x2000, 0x3000
    var map_index: usize = 0;
    for (0..4) |palette_index| {
        for (0..32 * 32) |_| {
            bg0_map[map_index].palette_index = @intCast(palette_index);
            map_index += 1;
        }
    }
}

pub fn main() void {
    initMap();
    display.ctrl.* = .{
        .bg0 = .enable,
        .obj = .enable,
    };

    var x: i10 = 0;
    var y: i10 = 0;
    var tx: u6 = 0;
    var ty: u6 = 0;
    var curr_screen_block: usize = 0;
    var prev_screen_block: usize = cross_ty * 32 + cross_tx;

    const bg0_map: [*]volatile bg.TextScreenEntry = @ptrCast(&bg.screen_block_ram[28]);
    bg0_map[prev_screen_block].tile_index += 1;

    while (true) {
        display.naiveVSync();

        _ = input.poll();

        x +%= input.getAxis(.horizontal).toInt();
        y +%= input.getAxis(.vertical).toInt();

        tx = @truncate((@as(u10, @bitCast(x)) >> 3) + cross_tx);
        ty = @truncate((@as(u10, @bitCast(y)) >> 3) + cross_ty);

        curr_screen_block = screenIndex(tx, ty, 64);

        if (prev_screen_block != curr_screen_block) {
            bg0_map[prev_screen_block].tile_index -%= 1;
            bg0_map[curr_screen_block].tile_index +%= 1;
            prev_screen_block = curr_screen_block;
        }

        bg.scroll[0].set(x, y);
    }
}
