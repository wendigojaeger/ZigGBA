const gba = @import("gba.zig");

pub fn Bitmap(comptime C: type, comptime width: u8, comptime height: u8) type {
    return struct {
        pub const Color = C;
        
        const HalfWordColor = if (@sizeOf(Color) == 2) Color else packed struct(u16) {
            lo: u8,
            hi: u8,
        };

        fn fullHalfwordColor(color: Color) HalfWordColor {
            return if (@sizeOf(Color) == 2) color else .{ .lo = color, .hi = color };
        }

        const real_width = @divExact(width, 2) * @sizeOf(Color);

        // TODO: Currently only works for mode 3, also, does it need to be volatile?
        pub inline fn screen() *volatile [height][real_width]HalfWordColor {
            return @ptrCast(gba.display.currentPage());
        }

        pub inline fn setPixel(x: u8, y: u8, color: Color) void {
            if (@sizeOf(Color) == 2) {
                screen()[y][x] = color;
            } else {
                if (x & 1 == 0) {
                    screen()[y][x >> 1].lo = color;
                } else {
                    screen()[y][x >> 1].hi = color;
                }
            }
        }

        // TODO: Test using full word memcpy.
        inline fn lineHorizontal(x1: u8, x2: u8, y: u8, color: Color) void {
            if (@sizeOf(Color) == 2) {
                for (screen()[y][x1 .. x2 + 1]) |*pixel| pixel.* = color;
            } else {
                const first = x1 >> 1;
                const last = x2 >> 1;
                const full: Color = .{ .lo = color, .hi = color };
                if (x1 & 1 == 0)
                    screen()[y][first] = full
                else
                    screen()[y][first].hi = color;
                for (screen[y][first + 1 .. last]) |*x| x.* = full;
                if (x2 & 1 == 0)
                    screen()[y][last].lo = color
                else
                    screen()[y][last] = full;
            }
        }

        pub fn line(start: [2]u8, end: [2]u8, color: Color) void {
            // y always moves down
            const p1, const p2 = if (start[1] < end[1])
                .{ start, end }
            else
                .{ end, start };
            const x1, const y1 = p1;
            const x2, const y2 = p2;
            //  Horizontal case
            if (y1 == y2) {
                lineHorizontal(@min(x1, x2), @max(x1, x2) + 1, y1, color);
            //  Vertical case
            } else if (x1 == x2) {
                for (y1..y2 + 1) |y| setPixel(x1, @truncate(y), color);
            } else {
                var diff: i16 = 0;
                var x, var y = p1;
                const dx, const x_step: u8 = if (x1 < x2)
                    .{ x2 - x1, 1 }
                else
                    .{ x1 - x2, @bitCast(@as(i8, -1)) };
                const dy = y2 - y1;
                while (true) {
                    setPixel(x, y, color);
                    if (x == x2 and y == y2)
                        break;
                    if (diff < 0) {
                        x +%= x_step;
                        diff += dy;
                    } else {
                        y += 1;
                        diff -= dx;
                    }
                }
            }
        }

        pub fn rect(top_left: [2]u8, bottom_right: [2]u8, color: Color) void {
            for (top_left[1]..bottom_right[1] + 1) |y| {
                lineHorizontal(top_left[0], bottom_right[0], @truncate(y), color);
            }
        }

        pub fn frame(top_left: [2]u8, bottom_right: [2]u8, color: Color) void {
            const left, const top = top_left;
            const right, const bottom = bottom_right;
            lineHorizontal(left, right, top, color);
            line(.{ left, top + 1 }, .{ left, bottom - 1 }, color);
            line(.{ right, top + 1 }, .{ right, bottom - 1 }, color);
            lineHorizontal(left, right, bottom, color);
        }

        // TODO: This should absolutely be a 32bit memcpy, but quick and dirty for now
        pub fn fill(color: Color) void {
            for (screen()[0..]) |*row| {
                for (row[0..]) |*cell| cell.* = fullHalfwordColor(color);
            }
        }
    };
}
