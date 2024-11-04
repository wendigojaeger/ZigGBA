const gba = @import("gba");
const input = gba.input;
const display = gba.display;
const bg = gba.bg;
const io = gba.io;

const brin = @import("brin.zig");

export var header linksection(".gbaheader") = gba.Header.init("TILEDEMO", "ATDE", "00", 0);

fn loadData() void {
    const mapRam: [*]volatile u16 = @ptrFromInt(@intFromPtr(gba.VRAM) + (30 * 2048));

    gba.memcpy32(bg.palette, &brin.pal, brin.pal.len * 2);
    gba.memcpy32(gba.VRAM, &brin.tiles, brin.tiles.len * 2);
    gba.memcpy32(mapRam, &brin.map, brin.map.len * 2);
}

pub fn main() noreturn {
    loadData();
    io.bg_ctrl[0] = .{
        .screen_base_block = 30,
        .tile_map_size = .{ .normal = .@"64x32" },
    };

    io.display_ctrl.* = .{
        .show = .{ .bg0 = true },
    };

    var x: i10 = 192;
    var y: i10 = 64;

    while (true) {
        display.naiveVSync();

        _ = input.poll();

        x +%= input.Axis.get(.Horizontal);
        y +%= input.Axis.get(.Vertical);

        io.bg_scroll[0].set(x, y);
    }
}
