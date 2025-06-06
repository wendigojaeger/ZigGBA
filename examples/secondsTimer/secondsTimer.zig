const gba = @import("gba");
const display = gba.display;
const bg = gba.bg;
const Timer = gba.timer.Timer;
const timers = gba.timer.timers;
const bios = gba.bios;

export const gameHeader linksection(".gbaheader") = gba.initHeader("SECSTIMER", "ASTE", "00", 0);

fn initMap() void {
    // Init background
    bg.ctrl[0] = bg.Control {
        .screen_base_block = 28,
        .tile_map_size = .{ .normal = .@"32x32" },
    };
    bg.scroll[0].set(0, 0);

    // Create tiles for numeric digits
    bg.tile_ram[0][0] = @bitCast([_]u32{
        0x11111110, 0x11000110, 0x11000110, 0x11000110,
        0x11000110, 0x11000110, 0x11111110, 0x00000000,
    });
    bg.tile_ram[0][1] = @bitCast([_]u32{
        0x11000000, 0x11000000, 0x11000000, 0x11000000,
        0x11000000, 0x11000000, 0x11000000, 0x00000000,
    });
    bg.tile_ram[0][2] = @bitCast([_]u32{
        0x11111110, 0x11000000, 0x11000000, 0x11111110,
        0x00000110, 0x00000110, 0x11111110, 0x00000000,
    });
    bg.tile_ram[0][3] = @bitCast([_]u32{
        0x11111110, 0x11000000, 0x11000000, 0x11111110,
        0x11000000, 0x11000000, 0x11111110, 0x00000000,
    });
    bg.tile_ram[0][4] = @bitCast([_]u32{
        0x11000110, 0x11000110, 0x11000110, 0x11111110,
        0x11000000, 0x11000000, 0x11000000, 0x00000000,
    });
    bg.tile_ram[0][5] = @bitCast([_]u32{
        0x11111110, 0x00000110, 0x00000110, 0x11111110,
        0x11000000, 0x11000000, 0x11111110, 0x00000000,
    });
    bg.tile_ram[0][6] = @bitCast([_]u32{
        0x11111110, 0x00000110, 0x00000110, 0x11111110,
        0x11000110, 0x11000110, 0x11111110, 0x00000000,
    });
    bg.tile_ram[0][7] = @bitCast([_]u32{
        0x11111110, 0x11000000, 0x11000000, 0x11000000,
        0x11000000, 0x11000000, 0x11000000, 0x00000000,
    });
    bg.tile_ram[0][8] = @bitCast([_]u32{
        0x11111110, 0x11000110, 0x11000110, 0x11111110,
        0x11000110, 0x11000110, 0x11111110, 0x00000000,
    });
    bg.tile_ram[0][9] = @bitCast([_]u32{
        0x11111110, 0x11000110, 0x11000110, 0x11111110,
        0x11000000, 0x11000000, 0x11111110, 0x00000000,
    });
    bg.tile_ram[0][10] = @bitCast([_]u32{
        0x00000000, 0x00000000, 0x00000000, 0x00000000,
        0x00000000, 0x00000000, 0x00000000, 0x00000000,
    });

    // Initialize a palette
    const bg_palette = &bg.palette.banks;
    bg_palette[0][1] = gba.Color.rgb(31, 31, 31);
    
    // Initialize the map to all blank tiles
    const bg0_map: [*]volatile bg.TextScreenEntry = @ptrCast(&bg.screen_block_ram[28]);
    for (0..32*32) |map_index| {
        bg0_map[map_index].palette_index = 0;
        bg0_map[map_index].tile_index = 10;
    }
}

pub fn main() void {
    initMap();
    display.ctrl.* = display.Control {
        .bg0 = .enable,
    };
    
    // Based on the example here: https://gbadev.net/tonc/timers.html
    // Timer 1 will overflow every 0x4000 * 1024 clock cycles,
    // which is the same as once per second.
    // When it oveflows, Timer 2 will be incremented by 1 due
    // to its "cascade" flag.
    timers[1] = Timer {
        .counter = @truncate(-0x4000),
        .ctrl = .{
            .freq = .cycles_1024,
            .enable = .enable,
        },
    };
    timers[2] = Timer {
        .counter = 0,
        .ctrl = .{
            .mode = .cascade,
            .enable = .enable,
        },
    };
    
    const bg0_map: [*]volatile bg.TextScreenEntry = @ptrCast(&bg.screen_block_ram[28]);
    
    while (true) {
        display.naiveVSync();
        
        // Convert elapsed seconds to a 2-digit display
        const digits = bios.div(timers[2].counter, 10);
        bg0_map[33].tile_index = @intCast(digits.quotient);
        bg0_map[34].tile_index = @intCast(digits.remainder);
    }
}
