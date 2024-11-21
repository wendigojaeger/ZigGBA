const gba = @import("gba");
const input = gba.input;
const display = gba.display;
const obj = gba.obj;

export var header linksection(".gbaheader") = gba.initHeader("OBJDEMO", "AODE", "00", 0);

const metr = @import("metroid_sprite_data.zig");

fn loadSpriteData() void {
    gba.mem.memcpy32(obj.tile_ram, &metr.tiles, metr.tiles.len * 4);
    gba.mem.memcpy32(obj.palette, &metr.pal, metr.pal.len * 4);
}

pub fn main() void {
    display.ctrl.* = .{
        .obj_mapping = .one_dimension,
        .obj = .enable,
    };

    loadSpriteData();

    const metroid = obj.allocate();
    metroid.* = .{
        .x_pos = 100,
        .y_pos = 150,
        .palette = 0,
        .tile_index = 0,
    };
    metroid.setSize(.@"64x64");

    var x: i9 = 96;
    var y: i8 = 32;
    var tile_index: i10 = 0;

    while (true) {
        display.naiveVSync();

        _ = input.poll();

        x +%= input.getAxis(.horizontal) * 2;
        y +%= input.getAxis(.vertical) * 2;

        tile_index +%= input.getAxis(.shoulders);

        if (input.isKeyJustPressed(.A)) {
            metroid.flipH();
        }
        if (input.isKeyJustPressed(.B)) {
            metroid.flipV();
        }

        metroid.palette = if (input.isKeyPressed(.select)) 1 else 0;

        display.ctrl.obj_mapping = if (input.isKeyPressed(.start)) .two_dimensions else .one_dimension;

        metroid.setPosition(@bitCast(x), @bitCast(y));
        metroid.tile_index = @bitCast(tile_index);

        obj.update(1);
    }
}
