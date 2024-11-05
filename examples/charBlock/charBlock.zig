const gba = @import("gba");
const input = gba.input;
const display = gba.display;
const bg = gba.bg;

const cbb_ids = @import("cbb_ids.zig");

const CharacterBlock4 = 0;
const ScreenBlock4 = 2;

const CharacterBlock8 = 2;
const ScreenBlock8 = 4;

export var gameHeader linksection(".gbaheader") = gba.Header.init("CHARBLOCK", "ASBE", "00", 0);

fn loadTiles() void {
    const tl: [*]align(4) bg.Tile = @ptrFromInt(@intFromPtr(&cbb_ids.ids_4_tiles[0]));
    const tl8: [*]align(4) bg.Tile8 = @ptrFromInt(@intFromPtr(&cbb_ids.ids_8_tiles[0]));

    // Loading tiles. 4-bit tiles to blocks 0 and 1
    bg.tile_memory[0][1] = tl[1];
    bg.tile_memory[0][2] = tl[2];
    bg.tile_memory[1][0] = tl[3];
    bg.tile_memory[1][1] = tl[4];

    // and the 8-bit tiles to blocks 2 though 5
    bg.tile_8_memory[2][1] = tl8[1];
    bg.tile_8_memory[2][2] = tl8[2];
    bg.tile_8_memory[3][0] = tl8[3];
    bg.tile_8_memory[3][1] = tl8[4];
    bg.tile_8_memory[4][0] = tl8[5];
    bg.tile_8_memory[4][1] = tl8[6];
    bg.tile_8_memory[5][0] = tl8[7];
    bg.tile_8_memory[5][1] = tl8[8];

    // Load palette
    gba.memcpy32(gba.bg.palette, &cbb_ids.ids_4_pal, cbb_ids.ids_4_pal.len * @sizeOf(c_uint));
    gba.memcpy32(gba.OBJ_PALETTE_RAM, &cbb_ids.ids_4_pal, cbb_ids.ids_4_pal.len * @sizeOf(c_uint));
}

fn initMaps() void {
    // map coords (0,2)
    const screenEntry4_ptr: ?[*]bg.TextScreenEntry = @ptrFromInt(@intFromPtr(&bg.screen_block_memory[ScreenBlock4][2 * 32]));
    // map coords (0, 8)
    const screenEntry8_ptr: ?[*]bg.TextScreenEntry = @ptrFromInt(@intFromPtr(&bg.screen_block_memory[ScreenBlock8][8 * 32]));

    if (screenEntry4_ptr) |screenEntry4| {
        // Show first tiles of char-blocks available to background 0
        // tiles 1, 2 of CharacterBlock4
        screenEntry4[0x01].tile_index = 0x0001;
        screenEntry4[0x02].tile_index = 0x0002;
        // tiles 0, 1 of CharacterBlock4+1
        screenEntry4[0x20].tile_index = 0x0200;
        screenEntry4[0x21].tile_index = 0x0201;
    }

    if (screenEntry8_ptr) |screenEntry8| {
        // Show first tiles of char-blocks available to background 1
        // tiles 1, 2 of CharacterBlock8 (== 2)
        screenEntry8[0x01].tile_index = 0x0001;
        screenEntry8[0x02].tile_index = 0x0002;

        // tiles 1, 2 of CharacterBlock8+1
        screenEntry8[0x20].tile_index = 0x0100;
        screenEntry8[0x21].tile_index = 0x0101;

        // tiles 1, 2 of char-block CharacterBlock8+2 (== CBB_OBJ_LO)
        screenEntry8[0x40].tile_index = 0x0200;
        screenEntry8[0x41].tile_index = 0x0201;

        // tiles 1, 2 of char-block CharacterBlock8+3 (== CBB_OBJ_HI)
        screenEntry8[0x60].tile_index = 0x0300;
        screenEntry8[0x61].tile_index = 0x0301;
    }
}

pub fn main() noreturn {
    loadTiles();

    initMaps();

    gba.io.display_ctrl.show = .{
        .bg0 = true,
        .bg1 = true,
        .obj_layer = true,
    };

    gba.io.bg_ctrl[0] = .{
        .tile_base_block = CharacterBlock4,
        .screen_base_block = ScreenBlock4,
    };

    gba.io.bg_ctrl[1] = .{ .tile_base_block = CharacterBlock8, .screen_base_block = ScreenBlock8, .palette_mode = .color_256 };

    while (true) {}
}
