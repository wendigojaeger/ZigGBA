const gba = @import("gba");
const input = gba.input;
const display = gba.display;
const bg = gba.bg;

const cbb_ids = @import("cbb_ids.zig");

const character_block_4 = 0;
const screen_block_4 = 2;

const character_block_8 = 2;
const screen_block_8 = 4;

export var header linksection(".gbaheader") = gba.initHeader("CHARBLOCK", "ASBE", "00", 0);

fn loadTiles() void {
    const tl4: [*]align(4) const bg.Tile = @ptrCast(&cbb_ids.ids_4_tiles);
    const tl8: [*]align(4) const bg.Tile8 = @ptrCast(&cbb_ids.ids_8_tiles);

    // Loading tiles. 4-bit tiles to blocks 0 and 1
    bg.tile_ram[0][1] = tl4[1];
    bg.tile_ram[0][2] = tl4[2];
    bg.tile_ram[1][0] = tl4[3];
    bg.tile_ram[1][1] = tl4[4];

    // and the 8-bit tiles to blocks 2 though 5
    bg.tile_8_ram[2][1] = tl8[1];
    bg.tile_8_ram[2][2] = tl8[2];
    bg.tile_8_ram[3][0] = tl8[3];
    bg.tile_8_ram[3][1] = tl8[4];
    bg.tile_8_ram[4][0] = tl8[5];
    bg.tile_8_ram[4][1] = tl8[6];
    bg.tile_8_ram[5][0] = tl8[7];
    bg.tile_8_ram[5][1] = tl8[8];

    // Load palette
    gba.mem.memcpy32(gba.bg.palette, &cbb_ids.ids_4_pal, cbb_ids.ids_4_pal.len * 4);
    gba.mem.memcpy32(gba.obj.palette, &cbb_ids.ids_4_pal, cbb_ids.ids_4_pal.len * 4);
}

fn initMaps() void {
    // map coords (0, 2)
    const screen_entry_4: []volatile bg.TextScreenEntry = bg.screen_block_ram[screen_block_4][2 * 32 ..];
    // map coords (0, 8)
    const screen_entry_8: []volatile bg.TextScreenEntry = bg.screen_block_ram[screen_block_8][8 * 32 ..];

    // Show first tiles of char-blocks available to background 0
    // tiles 1, 2 of CharacterBlock4
    screen_entry_4[0x01].tile_index = 0x0001;
    screen_entry_4[0x02].tile_index = 0x0002;
    // tiles 0, 1 of CharacterBlock4+1
    screen_entry_4[0x20].tile_index = 0x0200;
    screen_entry_4[0x21].tile_index = 0x0201;

    // Show first tiles of char-blocks available to background 1
    // tiles 1, 2 of CharacterBlock8 (== 2)
    screen_entry_8[0x01].tile_index = 0x0001;
    screen_entry_8[0x02].tile_index = 0x0002;

    // tiles 1, 2 of CharacterBlock8+1
    screen_entry_8[0x20].tile_index = 0x0100;
    screen_entry_8[0x21].tile_index = 0x0101;

    // tiles 1, 2 of char-block CharacterBlock8+2 (== CBB_OBJ_LO)
    screen_entry_8[0x40].tile_index = 0x0200;
    screen_entry_8[0x41].tile_index = 0x0201;

    // tiles 1, 2 of char-block CharacterBlock8+3 (== CBB_OBJ_HI)
    screen_entry_8[0x60].tile_index = 0x0300;
    screen_entry_8[0x61].tile_index = 0x0301;
}

pub fn main() void {
    loadTiles();

    initMaps();

    display.ctrl.* = .{
        .bg0 = .enable,
        .bg1 = .enable,
        .obj = .enable,
    };

    bg.ctrl[0] = .{
        .tile_base_block = character_block_4,
        .screen_base_block = screen_block_4,
    };

    bg.ctrl[1] = .{
        .tile_base_block = character_block_8,
        .screen_base_block = screen_block_8,
        .palette_mode = .color_256,
    };
}
