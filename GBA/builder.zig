const Builder = @import("std").build.Builder;
const LibExeObjStep = @import("std").build.LibExeObjStep;
const Step = @import("std").build.Step;
const builtin = @import("std").builtin;
const fmt = @import("std").fmt;
const FixedBufferAllocator = @import("std").heap.FixedBufferAllocator;
const std = @import("std");
const fs = @import("std").fs;
const ArrayList = @import("std").ArrayList;
const ImageConverter = @import("assetconverter/image_converter.zig").ImageConverter;

pub const ImageSourceTarget = @import("assetconverter/image_converter.zig").ImageSourceTarget;

const GBALinkerScript = "GBA/gba.ld";

var IsDebugOption: ?bool = null;

fn gbaThumbTarget() std.Target {
    return std.Target{
        .Cross = std.Target.Cross{
            .arch = std.Target.Arch{ .thumb = std.Target.Arch.Arm32.v4t },
            .os = .freestanding,
            .abi = .none,
        },
    };
}

pub fn addGBAStaticLibrary(b: *Builder, libraryName: []const u8, sourceFile: []const u8, isDebug: bool) *LibExeObjStep {
    const lib = b.addStaticLibrary(libraryName, sourceFile);

    lib.setTheTarget(gbaThumbTarget());

    lib.setLinkerScriptPath(GBALinkerScript);
    lib.setBuildMode(if (isDebug) builtin.Mode.Debug else builtin.Mode.ReleaseFast);

    return lib;
}

pub fn createGBALib(b: *Builder, isDebug: bool) *LibExeObjStep {
    return addGBAStaticLibrary(b, "ZigGBA", "GBA/gba.zig", isDebug);
}

pub fn addGBAExecutable(b: *Builder, romName: []const u8, sourceFile: []const u8) *LibExeObjStep {
    const exe = b.addExecutable(romName, sourceFile);

    var isDebug = false;
    if (IsDebugOption) |value| {
        isDebug = value;
    } else {
        isDebug = b.option(bool, "debug", "Generate a debug build for easier debugging with mGBA") orelse false;
        IsDebugOption = isDebug;
    }

    exe.setTheTarget(gbaThumbTarget());

    exe.setOutputDir("zig-cache/raw");
    exe.setLinkerScriptPath(GBALinkerScript);
    exe.setBuildMode(if (isDebug) builtin.Mode.Debug else builtin.Mode.ReleaseFast);

    const gbaLib = createGBALib(b, isDebug);
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

const Mode4ConvertStep = struct {
    step: Step,
    builder: *Builder,
    images: [] ImageSourceTarget,
    targetPalettePath: [] const u8,

    pub fn init(b: *Builder, images: [] ImageSourceTarget, targetPalettePath: [] const u8) Mode4ConvertStep {
        return Mode4ConvertStep {
            .builder = b,
            .step = Step.init(b.fmt("ConvertMode4Image {}", .{targetPalettePath}), b.allocator, make),
            .images = images,
            .targetPalettePath = targetPalettePath,
        };
    }

    fn make(step: *Step) !void {
        const self = @fieldParentPtr(Mode4ConvertStep, "step", step);
        const ImageSourceTargetList = ArrayList(ImageSourceTarget);

        var fullImages = ImageSourceTargetList.init(self.builder.allocator);
        defer fullImages.deinit();

        for (self.images) |imageSourceTarget| {
            try fullImages.append(ImageSourceTarget {
                .source = self.builder.pathFromRoot(imageSourceTarget.source),
                .target = self.builder.pathFromRoot(imageSourceTarget.target),
            });
        }
        const fullTargetPalettePath = self.builder.pathFromRoot(self.targetPalettePath);

        try ImageConverter.convertMode4Image(self.builder.allocator, fullImages.toSlice(), fullTargetPalettePath);
    }
};

pub fn convertMode4Images(libExe: *LibExeObjStep, images: [] ImageSourceTarget, targetPalettePath: [] const u8) void {
    const convertImageStep = libExe.builder.allocator.create(Mode4ConvertStep) catch unreachable;
    convertImageStep.* = Mode4ConvertStep.init(libExe.builder, images, targetPalettePath);
    libExe.step.dependOn(&convertImageStep.step);
}