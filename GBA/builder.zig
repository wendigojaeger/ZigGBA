const Builder = @import("std").build.Builder;
const LibExeObjStep = @import("std").build.LibExeObjStep;
const builtin = @import("std").builtin;
const fmt = @import("std").fmt;
const FixedBufferAllocator = @import("std").heap.FixedBufferAllocator;
const std = @import("std");
const fs = @import("std").fs;

const GBALinkerScript = "GBA/gba.ld";

fn gbaThumbTarget() std.Target {
    return std.Target{
        .Cross = std.Target.Cross{
            .arch = std.Target.Arch{ .thumb = std.Target.Arch.Arm32.v4t },
            .os = .freestanding,
            .abi = .none,
        },
    };
}

pub fn addGBAStaticLibrary(b: *Builder, libraryName: []const u8, sourceFile: []const u8) *LibExeObjStep {
    const lib = b.addStaticLibrary(libraryName, sourceFile);

    lib.setTheTarget(gbaThumbTarget());

    lib.setLinkerScriptPath(GBALinkerScript);
    lib.setBuildMode(builtin.Mode.ReleaseFast);

    return lib;
}

pub fn createGBALib(b: *Builder) *LibExeObjStep {
    return addGBAStaticLibrary(b, "ZigGBA", "GBA/gba.zig");
}

pub fn addGBAExecutable(b: *Builder, romName: []const u8, sourceFile: []const u8) *LibExeObjStep {
    const exe = b.addExecutable(romName, sourceFile);

    exe.setTheTarget(gbaThumbTarget());

    exe.setOutputDir("zig-cache/raw");
    exe.setLinkerScriptPath(GBALinkerScript);
    exe.setBuildMode(builtin.Mode.ReleaseFast);

    const gbaLib = createGBALib(b);
    exe.addPackagePath("gba", "GBA/gba.zig");
    exe.linkLibrary(gbaLib);

    var allocBuffer: [4 * 1024]u8 = undefined;
    var fixed = FixedBufferAllocator.init(allocBuffer[0..]);
    const fixedAllocator = &fixed.allocator;

    const outputPath = fmt.allocPrint(fixedAllocator, "zig-cache/bin/{}.gba", .{romName}) catch unreachable;

    if (fs.path.dirname(outputPath)) |dirPath| {
        _ = fs.makePath(fixedAllocator, dirPath) catch unreachable;
    }

    // TODO: Use builtin raw output when available in Zig compiler
    const objCopyCommand = if (builtin.os == builtin.Os.windows) "C:\\Programmation\\Zig\\llvm+clang-9.0.0-win64-msvc-mt\\bin\\llvm-objcopy.exe" else "llvm-objcopy";
    const buildGBARomCommand = b.addSystemCommand(&[_][]const u8{
        objCopyCommand, exe.getOutputPath(),
        "-O",           "binary",
        outputPath,
    });

    buildGBARomCommand.step.dependOn(&exe.step);

    b.default_step.dependOn(&buildGBARomCommand.step);

    return exe;
}
