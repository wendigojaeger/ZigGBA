const gba = @import("gba");
const input = gba.input;
const display = gba.display;
const obj = gba.obj;

export var gameHeader linksection(".gbaheader") = gba.Header.init("OBJDEMO", "AODE", "00", 0);

const metr = @import("metroid_sprite_data.zig");

fn loadSpriteData() void {
    gba.memcpy32(gba.SPRITE_VRAM, &metr.tiles, metr.tiles.len * 4);
    gba.memcpy32(gba.OBJ_PALETTE_RAM, &metr.pal, metr.pal.len * 4);
}

pub fn main() noreturn {
    gba.io.display_ctrl.* = .{
        .obj_mapping = .one_dimension,
        .show = .{ .obj_layer = true },
    };

    loadSpriteData();

    var metroid: *obj.Attribute = obj.allocate();
    metroid.x_pos = 100;
    metroid.y_pos = 150;
    metroid.palette = 0;
    metroid.tile_idx = 0;
    metroid.setSize(.@"64x64");

    var x: i9 = 96;
    var y: i8 = 32;
    var tileIndex: i10 = 0;

    while (true) {
        display.naiveVSync();

        _ = input.poll();

        x +%= input.Axis.get(.Horizontal) * 2;
        y +%= input.Axis.get(.Vertical) * 2;

        tileIndex += input.Axis.get(.Shoulders);

        if (input.isKeyJustPressed(.A)) {
            metroid.transform.normal.flip_h = !metroid.transform.normal.flip_h;
        }
        if (input.isKeyJustPressed(.B)) {
            metroid.transform.normal.flip_v = !metroid.transform.normal.flip_v;
        }

        metroid.palette = if (input.isKeyPressed(.Select)) 1 else 0;

        gba.io.display_ctrl.obj_mapping = if (input.isKeyPressed(.Start)) .two_dimensions else .one_dimension;

        metroid.setPosition(@bitCast(x), @bitCast(y));
        metroid.tile_idx = @bitCast(tileIndex);

        obj.update(1);
    }
}
