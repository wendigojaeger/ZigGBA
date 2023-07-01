const ArrayList = std.ArrayList;
const CrossTarget = std.zig.CrossTarget;
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const ImageConverter = @import("assetconverter/image_converter.zig").ImageConverter;
const Step = std.build.Step;
const builtin = std.builtin;
const fmt = std.fmt;
const fs = std.fs;
const std = @import("std");

pub const ImageSourceTarget = @import("assetconverter/image_converter.zig").ImageSourceTarget;

const GBALinkerScript = libRoot() ++ "/gba.ld";
const GBALibFile = libRoot() ++ "/gba.zig";

var IsDebugOption: ?bool = null;
var UseGDBOption: ?bool = null;

const gba_thumb_target = blk: {
    var target = CrossTarget{
        .cpu_arch = std.Target.Cpu.Arch.thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.arm7tdmi },
        .os_tag = .freestanding,
    };
    target.cpu_features_add.addFeature(@intFromEnum(std.Target.arm.Feature.thumb_mode));
    break :blk target;
};

fn libRoot() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}

pub fn addGBAStaticLibrary(b: *std.Build, libraryName: []const u8, sourceFile: []const u8, isDebug: bool) *std.build.CompileStep {
    const lib = b.addStaticLibrary(.{
        .name = libraryName,
        .root_source_file = .{ .path = sourceFile },
        .target = gba_thumb_target,
        .optimize = if (isDebug) .Debug else .ReleaseFast,
    });

    lib.setLinkerScriptPath(std.build.FileSource{ .path = GBALinkerScript });

    return lib;
}

pub fn createGBALib(b: *std.Build, isDebug: bool) *std.build.CompileStep {
    return addGBAStaticLibrary(b, "ZigGBA", GBALibFile, isDebug);
}

pub fn addGBAExecutable(b: *std.Build, romName: []const u8, sourceFile: []const u8) *std.build.CompileStep {
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

    const exe = b.addExecutable(.{
        .name = romName,
        .root_source_file = .{ .path = sourceFile },
        .target = gba_thumb_target,
        .optimize = if (isDebug) .Debug else .ReleaseFast,
    });

    exe.setLinkerScriptPath(std.build.FileSource{ .path = GBALinkerScript });
    if (useGDB) {
        b.installArtifact(exe);
    } else {
        const objcopy_step = exe.addObjCopy(.{
            .format = .bin,
        });

        const install_bin_step = b.addInstallBinFile(objcopy_step.getOutputSource(), b.fmt("{s}.gba", .{romName}));
        install_bin_step.step.dependOn(&objcopy_step.step);

        b.default_step.dependOn(&install_bin_step.step);
    }

    const gbaLib = createGBALib(b, isDebug);
    exe.addAnonymousModule("gba", .{ .source_file = .{ .path = GBALibFile } });
    exe.linkLibrary(gbaLib);

    b.default_step.dependOn(&exe.step);

    return exe;
}

const Mode4ConvertStep = struct {
    step: Step,
    images: []const ImageSourceTarget,
    targetPalettePath: []const u8,

    pub fn init(b: *std.Build, images: []const ImageSourceTarget, targetPalettePath: []const u8) Mode4ConvertStep {
        return Mode4ConvertStep{
            .step = Step.init(.{
                .id = .custom,
                .name = b.fmt("ConvertMode4Image {s}", .{targetPalettePath}),
                .owner = b,
                .makeFn = make,
            }),
            .images = images,
            .targetPalettePath = targetPalettePath,
        };
    }

    fn make(step: *Step, progress_node: *std.Progress.Node) !void {
        const self = @fieldParentPtr(Mode4ConvertStep, "step", step);
        const ImageSourceTargetList = ArrayList(ImageSourceTarget);

        var fullImages = ImageSourceTargetList.init(step.owner.allocator);
        defer fullImages.deinit();

        var node = progress_node.start("Converting mode4 images", 1);
        defer node.end();

        for (self.images) |imageSourceTarget| {
            try fullImages.append(ImageSourceTarget{
                .source = self.step.owner.pathFromRoot(imageSourceTarget.source),
                .target = self.step.owner.pathFromRoot(imageSourceTarget.target),
            });
        }

        const fullTargetPalettePath = self.step.owner.pathFromRoot(self.targetPalettePath);
        try ImageConverter.convertMode4Image(self.step.owner.allocator, fullImages.items, fullTargetPalettePath);
    }
};

pub fn convertMode4Images(compile_step: *std.build.CompileStep, images: []const ImageSourceTarget, targetPalettePath: []const u8) void {
    const convertImageStep = compile_step.step.owner.allocator.create(Mode4ConvertStep) catch unreachable;
    convertImageStep.* = Mode4ConvertStep.init(compile_step.step.owner, images, targetPalettePath);
    compile_step.step.dependOn(&convertImageStep.step);
}
