const gba = @import("gba.zig");

pub const Mode3 = Bitmap(gba.Color, 240, 160);
pub const Mode4 = Bitmap(u8, 240, 160);
pub const Mode5 = Bitmap(gba.Color, 160, 128);

/// x, y coordinates
const Point = [2]u8;

fn Bitmap(comptime Color: type, comptime width: u8, comptime height: u8) type {
    return struct {
        /// Page size of this bitmap type in bytes
        pub const page_size: u17 = @as(u17, @intCast(@sizeOf(Color))) * width * height;

        const HalfWordColor = if (@sizeOf(Color) == 2) Color else packed struct(u16) {
            lo: u8,
            hi: u8,

            fn withLo(self: HalfWordColor, color: u8) HalfWordColor {
                return .{
                    .lo = color,
                    .hi = self.hi,
                };
            }

            fn withHi(self: HalfWordColor, color: u8) HalfWordColor {
                return .{
                    .lo = self.lo,
                    .hi = color,
                };
            }
        };

        fn halfWordColor(color: Color) HalfWordColor {
            return if (@sizeOf(Color) == 2) color else .{ .lo = color, .hi = color };
        }

        const FullWordColor = packed struct(u32) {
            a: HalfWordColor,
            b: HalfWordColor,
        };

        fn fullWordColor(color: Color) FullWordColor {
            return .{
                .a = halfWordColor(color),
                .b = halfWordColor(color),
            };
        }

        const real_width = @divExact(width, 2) * @sizeOf(Color);

        /// Pointer to the currently active screen VRAM as a 2D array
        pub fn screen() *volatile [height][real_width]HalfWordColor {
            return @ptrCast(gba.display.currentPage());
        }

        pub fn setPixel(x: u8, y: u8, color: Color) void {
            if (@sizeOf(Color) == 2) {
                screen()[y][x] = color;
            } else {
                const cell = &screen()[y][x >> 1];
                cell.* = if (x & 1 == 0) cell.withLo(color) else cell.withHi(color);
            }
        }

        // TODO: Test using full word memcpy.
        fn lineHorizontal(x1: u8, x2: u8, y: u8, color: Color) void {
            if (@sizeOf(Color) == 2) {
                for (screen()[y][x1 .. x2 + 1]) |*pixel| pixel.* = color;
            } else {
                // Have to do first and last separately because we could need both pixels
                // or just one
                const l = x1 >> 1;
                const r = x2 >> 1;
                const first = &screen()[y][l];
                const last = &screen()[y][r];
                const full = halfWordColor(color);
                // Even = fill both, odd: only high byte
                first.* = if (x1 & 1 == 0) full else first.withHi(color);
                // Fill all the middle registers 2 at a time
                for (screen()[y][l + 1 .. r]) |*x| x.* = full;
                // Odd: fill both, even: only low byte
                last.* = if (x2 & 1 == 0) last.withLo(color) else full;
            }
        }

        pub fn line(start: Point, end: Point, color: Color) void {
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
                // Diagonal case
            } else {
                var diff: i16 = 0;
                var x, var y = p1;
                const dx, const x_step: u8 = if (x1 < x2)
                    .{ x2 - x1, 1 }
                else
                    .{ x1 - x2, @bitCast(-1) };
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

        pub fn rect(top_left: Point, bottom_right: Point, color: Color) void {
            for (top_left[1]..bottom_right[1] + 1) |y| {
                lineHorizontal(top_left[0], bottom_right[0], @truncate(y), color);
            }
        }

        pub fn frame(top_left: Point, bottom_right: Point, color: Color) void {
            const left, const top = top_left;
            const right, const bottom = bottom_right;
            lineHorizontal(left, right, top, color);
            line(.{ left, top + 1 }, .{ left, bottom - 1 }, color);
            line(.{ right, top + 1 }, .{ right, bottom - 1 }, color);
            lineHorizontal(left, right, bottom, color);
        }

        pub fn fill(color: Color) void {
            // TODO: clean this up when zig allows @ptrCast on slices changing length
            gba.bios.cpuFastSet(@ptrCast(&fullWordColor(color)), @as(*volatile [page_size / 4]u32, @ptrCast(@alignCast(gba.display.currentPage()))));
        }
    };
}
