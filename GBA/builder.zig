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
var UseGDBOption: ?bool = null;

const gba_arm_arch = std.Target.Arch{ .arm = std.Target.Arch.Arm32.v4t };
const gba_thumb_arch = std.Target.Arch{ .thumb = std.Target.Arch.Arm32.v4t };

fn gbaThumbTarget() std.Target {
    return std.Target{
        .Cross = std.Target.Cross{
            .arch = gba_thumb_arch,
            .os = .freestanding,
            .abi = .none,
            .cpu_features = blk: {
                var cpuFeatures = std.Target.CpuFeatures.initFromCpu(gba_thumb_arch, &std.Target.arm.cpu.arm7tdmi);
                cpuFeatures.features.addFeature(@enumToInt(std.Target.arm.Feature.thumb_mode));
                break :blk cpuFeatures;
            },
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

    exe.setTheTarget(gbaThumbTarget());
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
    images: []ImageSourceTarget,
    targetPalettePath: []const u8,

    pub fn init(b: *Builder, images: []ImageSourceTarget, targetPalettePath: []const u8) Mode4ConvertStep {
        return Mode4ConvertStep{
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
            try fullImages.append(ImageSourceTarget{
                .source = self.builder.pathFromRoot(imageSourceTarget.source),
                .target = self.builder.pathFromRoot(imageSourceTarget.target),
            });
        }
        const fullTargetPalettePath = self.builder.pathFromRoot(self.targetPalettePath);

        try ImageConverter.convertMode4Image(self.builder.allocator, fullImages.toSlice(), fullTargetPalettePath);
    }
};

pub fn convertMode4Images(libExe: *LibExeObjStep, images: []ImageSourceTarget, targetPalettePath: []const u8) void {
    const convertImageStep = libExe.builder.allocator.create(Mode4ConvertStep) catch unreachable;
    convertImageStep.* = Mode4ConvertStep.init(libExe.builder, images, targetPalettePath);
    libExe.step.dependOn(&convertImageStep.step);
}
