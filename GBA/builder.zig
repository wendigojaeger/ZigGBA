const ArrayList = std.ArrayList;
const Builder = std.build.Builder;
const CrossTarget = std.zig.CrossTarget;
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const ImageConverter = @import("assetconverter/image_converter.zig").ImageConverter;
const LibExeObjStep = std.build.LibExeObjStep;
const Step = std.build.Step;
const builtin = std.builtin;
const fmt = std.fmt;
const fs = std.fs;
const std = @import("std");

pub const ImageSourceTarget = @import("assetconverter/image_converter.zig").ImageSourceTarget;

const GBALinkerScript = "GBA/gba.ld";

var IsDebugOption: ?bool = null;
var UseGDBOption: ?bool = null;

const gba_thumb_target = blk: {
    var target = CrossTarget{
        .cpu_arch = std.Target.Cpu.Arch.thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.arm7tdmi },
        .os_tag = .freestanding,
    };
    target.cpu_features_add.addFeature(@enumToInt(std.Target.arm.Feature.thumb_mode));
    break :blk target;
};

pub fn addGBAStaticLibrary(b: *Builder, libraryName: []const u8, sourceFile: []const u8, isDebug: bool) *LibExeObjStep {
    const lib = b.addStaticLibrary(libraryName, sourceFile);

    lib.setTarget(gba_thumb_target);

    lib.setLinkerScriptPath(GBALinkerScript);
    lib.setBuildMode(if (isDebug) builtin.Mode.Debug else builtin.Mode.ReleaseFast);

    return lib;
}

pub fn createGBALib(b: *Builder, isDebug: bool) *LibExeObjStep {
    return addGBAStaticLibrary(b, "ZigGBA", "GBA/gba.zig", isDebug);
}

pub fn addGBAExecutable(b: *Builder, romName: []const u8, sourceFile: []const u8) *LibExeObjStep {
    const isDebug = blk: {
        if (IsDebugOption) |value| {
            break :blk value;
        } else {
            const newIsDebug = b.option(bool, "debug", "Generate a debug build") orelse false;
            IsDebugOption = newIsDebug;
            break :blk newIsDebug;
        }
    };

    const useGDB = blk: {
        if (UseGDBOption) |value| {
            break :blk value;
        } else {
            const gdb = b.option(bool, "gdb", "Generate a ELF file for easier debugging with mGBA remote GDB support") orelse false;
            UseGDBOption = gdb;
            break :blk gdb;
        }
    };

    const exe = b.addExecutable(romName, sourceFile);

    exe.setTarget(gba_thumb_target);
    exe.setLinkerScriptPath(GBALinkerScript);
    exe.setBuildMode(if (isDebug) builtin.Mode.Debug else builtin.Mode.ReleaseFast);
    if (useGDB) {
        exe.install();
    } else {
        exe.installRaw(b.fmt("{}.gba", .{romName}));
    }

    const gbaLib = createGBALib(b, isDebug);
    exe.addPackagePath("gba", "GBA/gba.zig");
    exe.linkLibrary(gbaLib);

    b.default_step.dependOn(&exe.step);

    return exe;
}

const Mode4ConvertStep = struct {
    step: Step,
    builder: *Builder,
    images: []const ImageSourceTarget,
    targetPalettePath: []const u8,

    pub fn init(b: *Builder, images: []const ImageSourceTarget, targetPalettePath: []const u8) Mode4ConvertStep {
        return Mode4ConvertStep{
            .builder = b,
            .step = Step.init(.Custom, b.fmt("ConvertMode4Image {}", .{targetPalettePath}), b.allocator, make),
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
            try fullImages.append(ImageSourceTarget{
                .source = self.builder.pathFromRoot(imageSourceTarget.source),
                .target = self.builder.pathFromRoot(imageSourceTarget.target),
            });
        }
        const fullTargetPalettePath = self.builder.pathFromRoot(self.targetPalettePath);

        try ImageConverter.convertMode4Image(self.builder.allocator, fullImages.items, fullTargetPalettePath);
    }
};

pub fn convertMode4Images(libExe: *LibExeObjStep, images: []const ImageSourceTarget, targetPalettePath: []const u8) void {
    const convertImageStep = libExe.builder.allocator.create(Mode4ConvertStep) catch unreachable;
    convertImageStep.* = Mode4ConvertStep.init(libExe.builder, images, targetPalettePath);
    libExe.step.dependOn(&convertImageStep.step);
}
