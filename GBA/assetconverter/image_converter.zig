const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const zigimg = @import("zigimg/zigimg.zig");
const OctTreeQuantizer = zigimg.OctTreeQuantizer;
const fs = std.fs;
const mem = std.mem;
const std = @import("std");

pub const ImageConverterError = error{InvalidPixelData};

const GBAColor = packed struct {
    r: u5,
    g: u5,
    b: u5,
};

pub const ImageSourceTarget = struct {
    source: []const u8,
    target: []const u8,
};

pub const ImageConverter = struct {
    pub fn convertMode4Image(allocator: Allocator, images: []ImageSourceTarget, targetPaletteFilePath: []const u8) !void {
        var quantizer = OctTreeQuantizer.init(allocator);
        defer quantizer.deinit();

        const ImageConvertInfo = struct {
            imageInfo: ImageSourceTarget,
            image: zigimg.Image,
        };

        var imageConvertList = ArrayList(ImageConvertInfo).init(allocator);
        defer imageConvertList.deinit();

        for (images) |imageInfo| {
            var convertInfo = try imageConvertList.addOne();
            convertInfo.imageInfo = imageInfo;
            convertInfo.image = try zigimg.Image.fromFilePath(allocator, imageInfo.source);

            var colorIt = convertInfo.image.iterator();

            while (colorIt.next()) |pixel| {
                try quantizer.addColor(pixel.toPremultipliedAlpha().toRgba32());
            }
        }

        var paletteStorage: [256]zigimg.color.Rgba32 = undefined;
        const palette = try quantizer.makePalette(255, paletteStorage[0..]);

        var paletteFile = try openWriteFile(targetPaletteFilePath);
        defer paletteFile.close();

        var paletteOutStream = paletteFile.writer();

        // Write palette file
        var paletteCount: usize = 0;
        for (palette) |entry| {
            const gbaColor = colorToGBAColor(entry);
            try paletteOutStream.writeInt(u16, @as(u15, @bitCast(gbaColor)), .little);
            paletteCount += 2;
        }

        // Align palette file to a power of 4
        var diff = mem.alignForward(usize, paletteCount, 4) - paletteCount;
        var index: usize = 0;
        while (index < diff) : (index += 1) {
            try paletteOutStream.writeInt(u8, 0, .little);
        }

        for (imageConvertList.items) |convertInfo| {
            var imageFile = try openWriteFile(convertInfo.imageInfo.target);
            defer imageFile.close();

            var imageOutStream = imageFile.writer();

            // Write image file
            var pixelCount: usize = 0;

            var colorIt = convertInfo.image.iterator();

            while (colorIt.next()) |pixel| {
                const rawPaletteIndex: usize = try quantizer.getPaletteIndex(pixel.toPremultipliedAlpha().toRgba32());
                const paletteIndex: u8 = @as(u8, @intCast(rawPaletteIndex));
                try imageOutStream.writeInt(u8, paletteIndex, .little);
                pixelCount += 1;
            }

            diff = mem.alignForward(usize, pixelCount, 4) - pixelCount;
            index = 0;
            while (index < diff) : (index += 1) {
                try imageOutStream.writeInt(u8, 0, .little);
            }
        }
    }

    fn openWriteFile(path: []const u8) !fs.File {
        return try fs.cwd().createFile(path, fs.File.CreateFlags{});
    }

    fn colorToGBAColor(color: zigimg.color.Rgba32) GBAColor {
        return GBAColor{
            .r = @as(u5, @intCast((color.r >> 3) & 0x1f)),
            .g = @as(u5, @intCast((color.g >> 3) & 0x1f)),
            .b = @as(u5, @intCast((color.b >> 3) & 0x1f)),
        };
    }
};
