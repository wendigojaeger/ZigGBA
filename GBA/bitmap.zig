const GBA = @import("core.zig").GBA;

pub const Bitmap16 = struct {
    pub fn line(x1: i32, y1: i32, x2: i32, y2: i32, color: u16, destinationBase: [*]volatile u16, rawPitch: i32) void {
        var ii: i32 = 0;
        var dx: i32 = 0;
        var dy: i32 = 0;
        var xstep: i32 = 0;
        var ystep: i32 = 0;
        var dd: i32 = 0;
        var destinationPitch: i32 = 0;
        destinationPitch = @divExact(rawPitch, 2);

        var destination = @as([*]u16, @ptrFromInt(@intFromPtr(destinationBase) + @as(usize, @intCast(y1)) * @as(usize, @intCast(rawPitch)) + @as(usize, @intCast(x1)) * 2));

        // Normalization
        if (x1 > x2) {
            xstep = -1;
            dx = x1 - x2;
        } else {
            xstep = 1;
            dx = x2 - x1;
        }
        if (y1 > y2) {
            ystep = -destinationPitch;
            dy = y1 - y2;
        } else {
            ystep = destinationPitch;
            dy = y2 - y1;
        }

        if (dy == 0) {
            // Horizontal line case
            ii = 0;
            while (ii <= dx) : (ii += 1) {
                destination[@as(usize, @bitCast(ii * xstep))] = color;
            }
        } else if (dx == 0) {
            // Vertical line case
            ii = 0;
            while (ii <= dy) : (ii += 1) {
                destination[@as(usize, @bitCast(ii * ystep))] = color;
            }
        } else if (dx >= dy) {
            // Diagonal, slope <= 1
            dd = 2 * dy - dx;
            ii = 0;
            var destinationIndex: i32 = 0;
            while (ii <= dx) : (ii += 1) {
                destination[@as(usize, @bitCast(destinationIndex))] = color;
                if (dd >= 0) {
                    dd -= 2 * dx;
                    destinationIndex += ystep;
                }
                dd += 2 * dy;
                destinationIndex += xstep;
            }
        } else {
            // Diagonal, slop > 1
            dd = 2 * dx - dy;
            ii = 0;
            var destinationIndex: i32 = 0;
            while (ii <= dy) : (ii += 1) {
                destination[@as(usize, @bitCast(destinationIndex))] = color;
                if (dd >= 0) {
                    dd -= 2 * dy;
                    destinationIndex += xstep;
                }

                dd += 2 * dx;
                destinationIndex += ystep;
            }
        }
    }

    pub fn rect(left: i32, top: i32, right: i32, bottom: i32, color: u16, destinationBase: [*]volatile u16, rawPitch: i32) void {
        var ix: i32 = 0;
        var iy: i32 = 0;
        const width: i32 = right - left;
        const height: i32 = bottom - top;
        const destinationPitch: i32 = @divExact(rawPitch, 2);

        var destination = @as([*]u16, @ptrFromInt(@intFromPtr(destinationBase) + @as(usize, @intCast(top)) * @as(usize, @intCast(rawPitch)) + @as(usize, @intCast(left)) * 2));

        iy = 0;
        while (iy < height) : (iy += 1) {
            const rectPitch: i32 = iy * destinationPitch;

            ix = 0;
            while (ix < width) : (ix += 1) {
                destination[@as(usize, @bitCast(rectPitch + ix))] = color;
            }
        }
    }

    pub fn frame(left: i32, top: i32, right: i32, bottom: i32, color: u16, destinationBase: [*]volatile u16, rawPitch: i32) void {
        const actualRight: i32 = right - 1;
        const actualBottom: i32 = bottom - 1;

        line(left, top, actualRight, top, color, destinationBase, rawPitch);
        line(left, actualBottom, actualRight, actualBottom, color, destinationBase, rawPitch);

        line(left, top, left, actualBottom, color, destinationBase, rawPitch);
        line(actualRight, top, actualRight, actualBottom, color, destinationBase, rawPitch);
    }
};
