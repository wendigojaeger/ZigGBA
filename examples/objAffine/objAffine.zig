const gba = @import("gba");
const input = gba.input;
const display = gba.display;
const obj = gba.obj;
const debug = gba.debug;
const math = gba.math;
const io = gba.io;

export var gameHeader linksection(".gbaheader") = gba.Header.init("OBJAFFINE", "AODE", "00", 0);
const metr = @import("metr.zig");
const metrPal = metr.pal;
const metrTiles = metr.tiles;
const metr_boxTiles = metr.box_tiles;

pub fn main() noreturn {
    io.display_ctrl.* = .{
        .obj_mapping = .one_dimension,
        .show = .{ .obj_layer = true, .bg0 = true },
    };

    debug.init();

    gba.memcpy32(gba.SPRITE_VRAM, &metr.box_tiles, metr.box_tiles.len * 4);
    gba.memcpy32(gba.OBJ_PALETTE_RAM, &metr.pal, metr.pal.len * 4);

    const metroid = obj.allocate();
    metroid.transform.affine_index = 0;
    metroid.setSize(.@"64x64");
    metroid.affine_mode = .affine;
    metroid.palette = 0;
    metroid.tile_index = 0;
    metroid.setPosition(96, 32);
    metroid.getAffine().setIdentity();

    const shadow_metroid = obj.allocate();
    shadow_metroid.transform.affine_index = 31;
    shadow_metroid.setSize(.@"64x64");
    shadow_metroid.affine_mode = .affine;
    shadow_metroid.palette = 1;
    shadow_metroid.tile_index = 0;
    shadow_metroid.setPosition(96, 32);
    shadow_metroid.getAffine().setIdentity();

    obj.update(2);

    while (true) {
        display.naiveVSync();

        _ = input.poll();
    }
}
