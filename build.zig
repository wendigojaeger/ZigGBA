const Builder = @import("std").build.Builder;
usingnamespace @import("GBA/builder.zig");

pub fn build(b: *Builder) void {
    _ = addGBAExecutable(b, "first", "examples/first/first.zig");
    _ = addGBAExecutable(b, "mode3draw", "examples/mode3draw/mode3draw.zig");
    _ = addGBAExecutable(b, "debugPrint", "examples/debugPrint/debugPrint.zig");

    // Mode 4 Flip
    const mode4flip = addGBAExecutable(b, "mode4flip", "examples/mode4flip/mode4flip.zig");
    convertMode4Images(mode4flip, &[_]ImageSourceTarget{
        .{
            .source = "examples/mode4flip/front.bmp",
            .target = "examples/mode4flip/front.agi",
        },
        .{
            .source = "examples/mode4flip/back.bmp",
            .target = "examples/mode4flip/back.agi",
        },
    }, "examples/mode4flip/mode4flip.agp");

    // Key demo, TODO: Use image created by the build system once we support indexed image
    const keydemo = addGBAExecutable(b, "keydemo", "examples/keydemo/keydemo.zig");
    keydemo.addCSourceFile("examples/keydemo/gba_pic.c", &[_][]const u8{"-std=c99"});

    // Simple OBJ demo, TODO: Use tile and palette data created by the build system
    const objDemo = addGBAExecutable(b, "objDemo", "examples/objDemo/objDemo.zig");
    objDemo.addCSourceFile("examples/objDemo/metroid_sprite_data.c", &[_][]const u8{"-std=c99"});

    // tileDemo, TODO: Use tileset, tile and palette created by the build system
    const tileDemo = addGBAExecutable(b, "tileDemo", "examples/tileDemo/tileDemo.zig");
    tileDemo.addCSourceFile("examples/tileDemo/brin.c", &[_][]const u8{"-std=c99"});

    // screenBlock
    _ = addGBAExecutable(b, "screenBlock", "examples/screenBlock/screenBlock.zig");

    // charBlock
    const charBlock = addGBAExecutable(b, "charBlock", "examples/charBlock/charBlock.zig");
    charBlock.addCSourceFile("examples/charBlock/cbb_ids.c", &[_][]const u8{"-std=c99"});

    // objAffine
    const objAffine = addGBAExecutable(b, "objAffine", "examples/objAffine/objAffine.zig");
    objAffine.addCSourceFile("examples/objAffine/metr.c", &[_][]const u8{"-std=c99"});
}
