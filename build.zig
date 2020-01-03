const Builder = @import("std").build.Builder;
usingnamespace @import("GBA/builder.zig");

pub fn build(b: *Builder) void {
    const first = addGBAExecutable(b, "first", "examples/first/first.zig");
    const mode3Draw = addGBAExecutable(b, "mode3draw", "examples/mode3draw/mode3draw.zig");
    const debugPrint = addGBAExecutable(b, "debugPrint", "examples/debugPrint/debugPrint.zig");

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

    // Key demo
    const keydemo = addGBAExecutable(b, "keydemo", "examples/keydemo/keydemo.zig");
    // TODO: Use image created by the build system once we support indexed image
    keydemo.addCSourceFile("examples/keydemo/gba_pic.c", &[_][]const u8{"-std=c99"});
}
