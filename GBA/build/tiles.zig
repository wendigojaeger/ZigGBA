const zigimg = @import("zigimg/zigimg.zig");
const std = @import("std");

/// GBA 16-bit RGB555 color.
pub const GBAColor = @import("../color.zig").Color;
/// RGB888 truecolor.
pub const ColorRgb888 = zigimg.color.Rgb24;
/// RGBA8888 truecolor with alpha channel.
pub const ColorRgba8888 = zigimg.color.Rgba32;

/// Enumeration of possible bit depths for GBA tile data. (Bits per pixel.)
pub const Bpp = @import("../color.zig").Color.Bpp;

/// Enumeration of options for how many blocks converted tile image data
/// is intended to fit within.
pub const ConvertFit = enum(u3) {
    /// Allow any number of tiles, up to 65,535.
    unlimited = 0,
    /// The number of tiles should fit within one block.
    /// This limit is 512 tiles with 4bpp, or 256 tiles with 8bpp.
    within_block = 1,
    /// The number of tiles should fit within two blocks, i.e. within
    /// the total space for sprite tile data.
    /// This limit is 1024 tiles with 4bpp, or 512 tiles with 8bpp.
    within_2_blocks = 2,
    /// The number of tiles should fit within three blocks.
    within_3_blocks = 3,
    /// The number of tiles should fit within four blocks, i.e. within
    /// the total space for bg tile data.
    /// This limit is 2048 tiles with 4bpp, or 1024 tiles with 8bpp.
    within_4_blocks = 4,
    /// The number of tiles should fit within five blocks.
    within_5_blocks = 5,
    /// The number of tiles should fit within all six blocks.
    /// This limit is 3072 tiles with 4bpp, or 1536 tiles with 8bpp.
    within_6_blocks = 6,
};

/// Options expected by the convertTiles function, to determine its behavior.
pub fn ConvertOptions(comptime PaletteCtxT: type) type {
    return struct {
        /// Allocator for intermediate memory allocations.
        allocator: std.mem.Allocator,
        /// Given a pixel location and color, get a palette index.
        palette_fn: *const fn (x: u16, y: u16, color: ColorRgba8888, bpp: Bpp, ctx: PaletteCtxT) u8,
        /// Context object shared between invocations of the palette callback.
        palette_ctx: PaletteCtxT,
        /// Value to use for padding behavior with pad_fit and
        /// pad_tiles settings.
        pad: u8 = 0,
        /// Produce an error if the tile data does not fit within
        /// the given constraint.
        fit: ConvertFit = .within_block,
        /// Whether to write 4 or 8 bits per pixel.
        bpp: Bpp,
        /// If the amount of tile data is smaller than indicated by fit,
        /// then pad the rest. (Does not apply when fit is unlimited.)
        pad_fit: bool = false,
        /// Pad the edges of the image to a multiple of 8 pixels,
        /// instead of producing an error for strangely sized images.
        pad_tiles: bool = false,
        /// If not set, then an empty input image will trigger an error.
        allow_empty: bool = false,
    };
}

/// Returned by convertTiles.
pub const ConvertOutput = struct {
    /// Buffer containing output data.
    /// This is image data in a raw format, ready to be inserted into GBA VRAM.
    data: []u8,
    /// Number of tiles represented in the output data.
    count: u16,
};

/// Errors that may be produced by convertTiles.
pub const ConvertError = error{
    /// Palette function returned a value that was out of range given the
    /// image encoding settings.
    UnexpectedPaletteIndex,
    /// The image width and height were not both multiples of 8 pixels,
    /// and the "pad_tiles" option was not used.
    UnexpectedImageSize,
    /// The image was in an unsupported pixel format.
    /// Try converting it using image.convert before passing it.
    UnexpectedImagePixelFormat,
    /// The image width and/or height was 0, and the "allow_empty"
    /// option was not used.
    EmptyImage,
    /// The image is larger than 65,355 tiles on either axis.
    ImageTooLarge,
    /// The image contains too much tile data to fit within the space
    /// determined by the "fit" option.
    TooManyTiles,
};

/// Helper to convert GBA color (5 bits per channel) to truecolor
/// (8 bits per channel).
pub fn gbaColorToRgb888(color: GBAColor) ColorRgb888 {
    // For 5-bit values, `(x << 3) | (x >> 2)` is almost exactly
    // equivalent to `round(x * (255f / 31f))`.
    return ColorRgb888{
        .r = ((@as(u8, color.r) << 3) | (color.r >> 2)),
        .g = ((@as(u8, color.g) << 3) | (color.g >> 2)),
        .b = ((@as(u8, color.b) << 3) | (color.b >> 2)),
    };
}

/// Convenience function for finding a best fit color within a truecolor
/// palette to match a color found in an image.
/// When using this function, []ColorRgb888 should be provided as the CtxT
/// comptime argument to a convertTiles call. Only the first 16 items are
/// considered for 4bpp tiles, and only the first 256 items for 8bpp tiles.
/// The first palette color is treated as full transparency, to reflect
/// GBA rendering behavior.
pub fn getNearestPaletteColor(
    _: u16, // x
    _: u16, // y
    color: ColorRgba8888,
    bpp: Bpp,
    pal: []const ColorRgb888,
) u8 {
    if (color.a < 0xff) {
        // Transparent pixels are always palette index 0
        return 0;
    }
    const pal_i_max: usize = if (bpp == .bpp_4) 0xf else 0xff;
    var pal_i: usize = 1;
    var pal_nearest_i: u8 = 0;
    var pal_nearest_dist: i32 = 0;
    while (pal_i <= pal_i_max and pal_i < pal.len) {
        const pal_col = pal[pal_i];
        const dr = color.r - @as(i32, pal_col.r);
        const dg = color.g - @as(i32, pal_col.g);
        const db = color.b - @as(i32, pal_col.b);
        // Compute an approximation of perceptual color distance.
        // Human eyes are most sensitive to differences in green and
        // least sensitive to differences in blue.
        const dist: i32 = (
            ((dg * dg) << 2) +
            ((dr * dr) << 1) +
            (db * db)
        );
        if (pal_nearest_i <= 0 or dist < pal_nearest_dist) {
            pal_nearest_i = @truncate(pal_i);
            pal_nearest_dist = dist;
        }
        pal_i += 1;
    }
    return pal_nearest_i;
}

/// Convenience function for finding a best fit color within a GBA
/// palette to match a color found in an image.
/// When using this function, []GBAColor should be provided as the CtxT
/// comptime argument to a convertTiles call. Only the first 16 items are
/// considered for 4bpp tiles, and only the first 256 items for 8bpp tiles.
/// The first palette color is treated as full transparency, to reflect
/// GBA rendering behavior.
pub fn getNearestGbaPaletteColor(
    _: u16, // x
    _: u16, // y
    color: ColorRgba8888,
    bpp: Bpp,
    pal: []const GBAColor,
) u8 {
    if (color.a < 0xff) {
        // Transparent pixels are always palette index 0
        return 0;
    }
    const pal_i_max: usize = if (bpp == .bpp_4) 0xf else 0xff;
    var pal_i: usize = 1;
    var pal_nearest_i: u8 = 0;
    var pal_nearest_dist: i32 = 0;
    while (pal_i <= pal_i_max and pal_i < pal.len) {
        const pal_col = gbaColorToRgb888(pal[pal_i]);
        const dr = color.r - @as(i32, pal_col.r);
        const dg = color.g - @as(i32, pal_col.g);
        const db = color.b - @as(i32, pal_col.b);
        // Compute an approximation of perceptual color distance.
        // Human eyes are most sensitive to differences in green and
        // least sensitive to differences in blue.
        const dist: i32 = (((dg * dg) << 2) +
            ((dr * dr) << 1) +
            (db * db));
        if (pal_nearest_i <= 0 or dist < pal_nearest_dist) {
            pal_nearest_i = pal_i;
            pal_nearest_dist = dist;
        }
        pal_i += 1;
    }
    return pal_nearest_i;
}

/// This is a convenience wrapper around convertTiles which accepts
/// an image file path to read image data from.
pub fn convertImagePath(
    comptime CtxT: type,
    image_path: []const u8,
    opt: ConvertOptions(CtxT),
) (
    ConvertError ||
    std.mem.Allocator.Error ||
    zigimg.Image.ReadError ||
    std.fs.File.OpenError
)!ConvertOutput {
    var image = try zigimg.Image.fromFilePath(opt.allocator, image_path);
    defer image.deinit();
    return convertImage(CtxT, image, opt);
}

/// This is a convenience wrapper around convertTiles which accepts
/// both an image file path to read image data from and an output file path
/// to write the resulting data to.
pub fn convertSaveImagePath(
    comptime CtxT: type,
    image_path: []const u8,
    output_path: []const u8,
    opt: ConvertOptions(CtxT),
) (
    ConvertError ||
    std.mem.Allocator.Error ||
    zigimg.Image.ReadError ||
    std.fs.File.OpenError ||
    std.posix.WriteError
)!void {
    const tiles_data = try convertImagePath(CtxT, image_path, opt);
    defer opt.allocator.free(tiles_data.data);
    var file = try std.fs.cwd().createFile(output_path, .{});
    defer file.close();
    try file.writeAll(tiles_data.data);
}

/// Convert an arbitrary image to uncompressed tile data which may be
/// copied as-is into VRAM tile memory.
/// Tiles are taken from the image data in 8x8 pixel blocks, starting
/// in the top left corner (at 0, 0) proceeding in rows from left to right,
/// then top to bottom.
/// If the image contains more tiles than will fit into a single charblock
/// in the GBA's VRAM, you will need to make this intention explicit in
/// the options object. Otherwise, the function will fail with an error.
/// The limit per charblock is 128 4bpp tiles or 64 8bpp tiles.
/// When conversion is successful, the function returns a buffer allocated
/// using the provided allocator, containing the converted image data.
pub fn convertImage(
    comptime CtxT: type,
    image: zigimg.Image,
    opt: ConvertOptions(CtxT),
) (ConvertError || std.mem.Allocator.Error)!ConvertOutput {
    if (image.pixelFormat() == .invalid) {
        return ConvertError.UnexpectedImagePixelFormat;
    }
    // Check image size
    if (image.width > 0xffff or image.height > 0xffff) {
        return ConvertError.ImageTooLarge;
    }
    else if ((image.width <= 0 or image.height <= 0) and !opt.allow_empty) {
        return ConvertError.EmptyImage;
    }
    var image_tiles_x: u16 = @truncate(image.width >> 3);
    var image_tiles_y: u16 = @truncate(image.height >> 3);
    if (image.width & 0x7 != 0) {
        if (!opt.pad_tiles) {
            return ConvertError.UnexpectedImageSize;
        }
        image_tiles_x += 1;
    }
    if (image.height & 0x7 != 0) {
        if (!opt.pad_tiles) {
            return ConvertError.UnexpectedImageSize;
        }
        image_tiles_y += 1;
    }
    const bpp_shift: u4 = if (opt.bpp == .bpp_4) 0 else 1;
    const tile_count = image_tiles_x * image_tiles_y;
    const tile_limit = (512 * @as(u16, @intFromEnum(opt.fit))) >> bpp_shift;
    if (opt.fit == .unlimited) {
        if (tile_count >= 0xffff) {
            return ConvertError.TooManyTiles;
        }
    }
    else {
        if (tile_count > tile_limit) {
            return ConvertError.TooManyTiles;
        }
    }
    // Encode image data
    var data = std.ArrayList(u8).init(opt.allocator);
    defer data.deinit();
    var tile_x: u16 = 0;
    var tile_y: u16 = 0;
    var pal_index_prev: u8 = 0;
    for (0..tile_count) |_| {
        for (0..8) |pixel_y| {
            for (0..8) |pixel_x| {
                const image_x = tile_x + pixel_x;
                const image_y = tile_y + pixel_y;
                const image_i = image_x + (image.width * image_y);
                var pal_index: u8 = 0;
                if (image_i >= image.pixels.len()) {
                    pal_index = opt.pad;
                }
                else {
                    const px = getImagePixelRgba8888(image, image_i);
                    pal_index = opt.palette_fn(
                        @truncate(image_x),
                        @truncate(image_y),
                        px,
                        opt.bpp,
                        opt.palette_ctx,
                    );
                }
                if (opt.bpp == .bpp_4) {
                    if (pal_index >= 16) {
                        return ConvertError.UnexpectedPaletteIndex;
                    }
                    if ((pixel_x & 1) != 0) {
                        try data.append(pal_index_prev | (pal_index << 4));
                    }
                    else {
                        pal_index_prev = pal_index;
                    }
                }
                else {
                    try data.append(pal_index);
                }
            }
        }
        tile_x += 8;
        if (tile_x >= image.width) {
            tile_x = 0;
            tile_y += 8;
        }
    }
    // Apply padding, when necessary
    if (opt.pad_fit and opt.fit != .unlimited and data.items.len < tile_limit) {
        try data.appendNTimes(opt.pad, tile_limit - data.items.len);
    }
    // All done
    return ConvertOutput{
        .data = try data.toOwnedSlice(),
        .count = tile_count,
    };
}

/// Helper to get RGBA8888 color from an image.
fn getImagePixelRgba8888(image: zigimg.Image, index: usize) ColorRgba8888 {
    return switch (image.pixels) {
        .invalid => .{ .r = 0, .g = 0, .b = 0 },
        .indexed1 => |px| px.palette[px.indices[index]],
        .indexed2 => |px| px.palette[px.indices[index]],
        .indexed4 => |px| px.palette[px.indices[index]],
        .indexed8 => |px| px.palette[px.indices[index]],
        .indexed16 => |px| px.palette[px.indices[index]],
        .grayscale1 => |px| {
            const i: u8 = if (px[index].value == 0) 0 else 0xff;
            return .{ .r = i, .g = i, .b = i };
        },
        .grayscale2 => |px| {
            const i_table = [4]u8{ 0x00, 0x55, 0xaa, 0xff };
            const i = i_table[px[index].value];
            return .{ .r = i, .g = i, .b = i };
        },
        .grayscale4 => |px| {
            const i = (@as(u8, px[index].value) << 4) | px[index].value;
            return .{ .r = i, .g = i, .b = i };
        },
        .grayscale8 => |px| {
            const i = px[index].value;
            return .{ .r = i, .g = i, .b = i };
        },
        .grayscale8Alpha => |px| {
            const i = px[index].value;
            return .{ .r = i, .g = i, .b = i, .a = px[index].alpha };
        },
        .grayscale16 => |px| {
            const i: u8 = @truncate(px[index].value);
            return .{ .r = i, .g = i, .b = i };
        },
        .grayscale16Alpha => |px| {
            const i: u8 = @truncate(px[index].value);
            const a: u8 = @truncate(px[index].alpha);
            return .{ .r = i, .g = i, .b = i, .a = a };
        },
        .rgb24 => |px| .{
            .r = px[index].r,
            .g = px[index].g,
            .b = px[index].b,
        },
        .rgba32 => |px| px[index],
        .rgb332 => |px| .{
            .r = px[index].r,
            .g = px[index].g,
            .b = px[index].b,
        },
        .rgb565 => |px| .{
            .r = px[index].r,
            .g = px[index].g,
            .b = px[index].b,
        },
        .rgb555 => |px| .{
            .r = px[index].r,
            .g = px[index].g,
            .b = px[index].b,
        },
        .bgr555 => |px| .{
            .r = px[index].r,
            .g = px[index].g,
            .b = px[index].b,
        },
        .bgr24 => |px| .{
            .r = px[index].r,
            .g = px[index].g,
            .b = px[index].b,
        },
        .bgra32 => |px| .{
            .r = px[index].r,
            .g = px[index].g,
            .b = px[index].b,
            .a = px[index].a,
        },
        .rgb48 => |px| .{
            .r = @truncate(px[index].r),
            .g = @truncate(px[index].g),
            .b = @truncate(px[index].b),
        },
        .rgba64 => |px| .{
            .r = @truncate(px[index].r),
            .g = @truncate(px[index].g),
            .b = @truncate(px[index].b),
            .a = @truncate(px[index].a),
        },
        .float32 => |px| .{
            .r = @intFromFloat(@round(px[index].r)),
            .g = @intFromFloat(@round(px[index].g)),
            .b = @intFromFloat(@round(px[index].b)),
            .a = @intFromFloat(@round(px[index].a)),
        },
    };
}
