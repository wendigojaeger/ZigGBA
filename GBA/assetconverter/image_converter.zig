const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const zigimg = @import("zigimg/zigimg.zig");
const OctTreeQuantizer = zigimg.OctTreeQuantizer;
const fs = std.fs;
const mem = std.mem;
const std = @import("std");

pub const ImageConverterError = error{InvalidPixelData};

const GBAColor = @import("../Palette.zig").Color;

pub const ImageSourceTarget = struct {
    source: []const u8,
    target: []const u8,
};

pub const ImageConverter = struct {
    pub fn convertMode4Image(allocator: Allocator, images: []ImageSourceTarget, target_palette_file_path: []const u8) !void {
        var quantizer = OctTreeQuantizer.init(allocator);
        defer quantizer.deinit();

        const ImageConvertInfo = struct {
            info: ImageSourceTarget,
            image: zigimg.Image,
        };

        var image_convert_list = ArrayList(ImageConvertInfo).init(allocator);
        defer image_convert_list.deinit();

        for (images) |info| {
            const image = try zigimg.Image.fromFilePath(allocator, info.source);
            var color_it = image.iterator();

            while (color_it.next()) |pixel| {
                try quantizer.addColor(pixel.toPremultipliedAlpha().toRgba32());
            }

            try image_convert_list.append(.{
                .info = info,
                .image = image,
            });
        }

        var palette_storage: [256]zigimg.color.Rgba32 = undefined;
        const palette = quantizer.makePalette(256, palette_storage[0..]);

        var palette_file = try openWriteFile(target_palette_file_path);
        defer palette_file.close();

        var palette_out_stream = palette_file.writer();

        // Write palette file
        var palette_count: usize = 0;
        for (palette) |entry| {
            const gba_color = colorToGBAColor(entry);
            try palette_out_stream.writeInt(u16, @bitCast(gba_color), .little);
            palette_count += 2;
        }

        // Align palette file to a power of 4
        var diff = mem.alignForward(usize, palette_count, 4) - palette_count;
        for (0..diff) |_| {
            try palette_out_stream.writeInt(u8, 0, .little);
        }

        for (image_convert_list.items) |convert| {
            var image_file = try openWriteFile(convert.info.target);
            defer image_file.close();

            var image_out_stream = image_file.writer();

            // Write image file
            var pixel_count: usize = 0;

            var color_it = convert.image.iterator();

            while (color_it.next()) |pixel| : (pixel_count += 1) {
                const raw_palette_index: usize = try quantizer.getPaletteIndex(pixel.toPremultipliedAlpha().toRgba32());
                const palette_index: u8 = @as(u8, @intCast(raw_palette_index));
                try image_out_stream.writeInt(u8, palette_index, .little);
            }

            diff = mem.alignForward(usize, pixel_count, 4) - pixel_count;
            for (0..diff) |_| {
                try image_out_stream.writeInt(u8, 0, .little);
            }
        }
    }

    fn openWriteFile(path: []const u8) !fs.File {
        return try fs.cwd().createFile(path, .{});
    }

    fn colorToGBAColor(color: zigimg.color.Rgba32) GBAColor {
        return .{
            .r = @truncate(color.r >> 3),
            .g = @truncate(color.g >> 3),
            .b = @truncate(color.b >> 3),
        };
    }
};
