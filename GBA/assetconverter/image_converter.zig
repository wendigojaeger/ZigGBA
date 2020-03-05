const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Color = @import("zigimg/zigimg.zig").color.Color;
const OctTreeQuantizer = @import("zigimg/zigimg.zig").octree_quantizer.OctTreeQuantizer;
const bmp = @import("zigimg/zigimg.zig").bmp;
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
    pub fn convertMode4Image(allocator: *Allocator, images: []ImageSourceTarget, targetPaletteFilePath: []const u8) !void {
        var quantizer = OctTreeQuantizer.init(allocator);
        defer quantizer.deinit();

        const ImageConvertInfo = struct {
            imageInfo: ImageSourceTarget,
            image: bmp.Bitmap,
        };

        var imageConvertList = ArrayList(ImageConvertInfo).init(allocator);
        defer imageConvertList.deinit();

        for (images) |imageInfo| {
            var convertInfo = try imageConvertList.addOne();
            convertInfo.imageInfo = imageInfo;
            convertInfo.image = try bmp.Bitmap.fromFile(allocator, imageInfo.source);

            if (convertInfo.image.pixels) |pixelData| {
                for (pixelData) |pixel| {
                    try quantizer.addColor(pixel.premultipliedAlpha());
                }
            } else {
                return ImageConverterError.InvalidPixelData;
            }
        }

        var paletteStorage: [256]Color = undefined;
        var palette = try quantizer.makePalette(255, paletteStorage[0..]);

        var paletteFile = try openWriteFile(targetPaletteFilePath);
        defer paletteFile.close();

        var paletteOut = paletteFile.outStream();
        var paletteOutStream = &paletteOut.stream;

        // Write palette file
        var paletteCount: usize = 0;
        for (palette) |entry| {
            const gbaColor = colorToGBAColor(entry);
            try paletteOutStream.writeIntLittle(u15, @bitCast(u15, gbaColor));
            paletteCount += 2;
        }

        // Align palette file to a power of 4
        var diff = mem.alignForward(paletteCount, 4) - paletteCount;
        var index: usize = 0;
        while (index < diff) : (index += 1) {
            try paletteOutStream.writeIntLittle(u8, 0);
        }

        for (imageConvertList.toSlice()) |convertInfo| {
            if (convertInfo.image.pixels) |pixelData| {
                var imageFile = try openWriteFile(convertInfo.imageInfo.target);
                defer imageFile.close();

                var imageOut = imageFile.outStream();
                var imageOutStream = &imageOut.stream;

                // Write image file
                var pixelCount: usize = 0;
                for (pixelData) |pixel| {
                    var rawPaletteIndex: usize = try quantizer.getPaletteIndex(pixel.premultipliedAlpha());
                    var paletteIndex: u8 = @intCast(u8, rawPaletteIndex);
                    try imageOutStream.writeIntLittle(u8, paletteIndex);
                    pixelCount += 1;
                }

                diff = mem.alignForward(pixelCount, 4) - pixelCount;
                index = 0;
                while (index < diff) : (index += 1) {
                    try imageOutStream.writeIntLittle(u8, 0);
                }
            }
        }
    }

    fn openWriteFile(path: []const u8) !fs.File {
        return try fs.cwd().createFile(path, fs.File.CreateFlags{});
    }

    fn colorToGBAColor(color: Color) GBAColor {
        return GBAColor{
            .r = @intCast(u5, (color.R >> 3) & 0x1f),
            .g = @intCast(u5, (color.G >> 3) & 0x1f),
            .b = @intCast(u5, (color.B >> 3) & 0x1f),
        };
    }
};
