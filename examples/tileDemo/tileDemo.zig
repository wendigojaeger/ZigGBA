const gba = @import("gba");
const input = gba.input;
const display = gba.display;
const bg = gba.bg;
const brin = @import("brin.zig");

export var header linksection(".gbaheader") = gba.initHeader("TILEDEMO", "ATDE", "00", 0);

fn loadData() void {
    const map_ram: [*]volatile u16 = @ptrFromInt(@intFromPtr(display.vram) + (30 * 2048));

    gba.mem.memcpy32(bg.palette, &brin.pal, brin.pal.len * 2);
    gba.mem.memcpy32(bg.tile_ram, &brin.tiles, brin.tiles.len * 2);
    gba.mem.memcpy32(map_ram, &brin.map, brin.map.len * 2);
}

pub export fn main() void {
    loadData();
    bg.ctrl[0] = .{
        .screen_base_block = 30,
        .tile_map_size = .{ .normal = .@"64x32" },
    };

    display.ctrl.* = .{
        .bg0 = .enable,
    };

    var x: i10 = 192;
    var y: i10 = 64;

    while (true) {
        display.naiveVSync();

        _ = input.poll();

        x +%= input.getAxis(.horizontal).toInt();
        y +%= input.getAxis(.vertical).toInt();

        bg.scroll[0].set(x, y);
    }
}
