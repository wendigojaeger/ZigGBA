const std = @import("std");
const GBABuilder = @import("GBA/build/builder.zig");

pub fn build(b: *std.Build) void {
    _ = GBABuilder.addGBAExecutable(b, "first", "examples/first/first.zig");
    _ = GBABuilder.addGBAExecutable(b, "mode3draw", "examples/mode3draw/mode3draw.zig");
    _ = GBABuilder.addGBAExecutable(b, "mode4draw", "examples/mode4draw/mode4draw.zig");
    _ = GBABuilder.addGBAExecutable(b, "debugPrint", "examples/debugPrint/debugPrint.zig");
    _ = GBABuilder.addGBAExecutable(b, "secondsTimer", "examples/secondsTimer/secondsTimer.zig");

    // Mode 4 Flip
    const mode4flip = GBABuilder.addGBAExecutable(b, "mode4flip", "examples/mode4flip/mode4flip.zig");
    GBABuilder.convertMode4Images(mode4flip, &[_]GBABuilder.ImageSourceTarget{
        .{
            .source = "examples/mode4flip/front.bmp",
            .target = "examples/mode4flip/front.agi",
        },
        .{
            .source = "examples/mode4flip/back.bmp",
            .target = "examples/mode4flip/back.agi",
        },
    }, "examples/mode4flip/mode4flip.agp");
    
    // Music example (Jesu, Joy of Man's Desiring)
    var jesuMusic_palette = [_]GBABuilder.tiles.ColorRgb888 {
        .{ .r = 0, .g = 0, .b = 0 }, // Transparency
        .{ .r = 255, .g = 255, .b = 255 },
        .{ .r = 0, .g = 0, .b = 0 },
    };
    _ = GBABuilder.addGBAExecutable(b, "jesuMusic", "examples/jesuMusic/jesuMusic.zig");
    GBABuilder.tiles.convertSaveImagePath(
        []GBABuilder.tiles.ColorRgb888,
        "examples/jesuMusic/charset.png",
        "examples/jesuMusic/charset.bin",
        .{
            .allocator = std.heap.page_allocator,
            .bpp = .bpp_4,
            .palette_fn = GBABuilder.tiles.getNearestPaletteColor,
            .palette_ctx = jesuMusic_palette[0..],
        },
    ) catch {};

    // Key demo, TODO: Use image created by the build system once we support indexed image
    _ = GBABuilder.addGBAExecutable(b, "keydemo", "examples/keydemo/keydemo.zig");
    // keydemo.addCSourceFile(.{
    //     .file = .{ .src_path = .{ .owner = b, .sub_path = "examples/keydemo/gba_pic.c" } },
    //     .flags = &[_][]const u8{"-std=c99"},
    // });

    // Simple OBJ demo, TODO: Use tile and palette data created by the build system
    _ = GBABuilder.addGBAExecutable(b, "objDemo", "examples/objDemo/objDemo.zig");
    // objDemo.addCSourceFile(.{
    //     .file = .{ .src_path = .{ .owner = b, .sub_path = "examples/objDemo/metroid_sprite_data.c" } },
    //     .flags = &[_][]const u8{"-std=c99"},
    // });

    // tileDemo, TODO: Use tileset, tile and palette created by the build system
    _ = GBABuilder.addGBAExecutable(b, "tileDemo", "examples/tileDemo/tileDemo.zig");
    // tileDemo.addCSourceFile(.{
    //     .file = .{ .src_path = .{ .owner = b, .sub_path = "examples/tileDemo/brin.c" } },
    //     .flags = &[_][]const u8{"-std=c99"},
    // });

    // screenBlock
    _ = GBABuilder.addGBAExecutable(b, "screenBlock", "examples/screenBlock/screenBlock.zig");

    // charBlock
    _ = GBABuilder.addGBAExecutable(b, "charBlock", "examples/charBlock/charBlock.zig");
    // charBlock.addCSourceFile(.{
    //     .file = .{ .src_path = .{.owner = b, .sub_path = "examples/charBlock/cbb_ids.c" } },
    //     .flags = &[_][]const u8{"-std=c99"},
    // });

    // objAffine
    _ = GBABuilder.addGBAExecutable(b, "objAffine", "examples/objAffine/objAffine.zig");
    // objAffine.addCSourceFile(.{
    //     .file = .{ .src_path = .{ .owner = b, .sub_path = "examples/objAffine/metr.c" } },
    //     .flags = &[_][]const u8{"-std=c99"},
    // });
}
