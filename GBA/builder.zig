const std = @import("std");
const ImageConverter = @import("assetconverter/image_converter.zig").ImageConverter;
const ArrayList = std.ArrayList;
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const Step = std.Build.Step;
const builtin = std.builtin;
const fmt = std.fmt;
const fs = std.fs;

pub const ImageSourceTarget = @import("assetconverter/image_converter.zig").ImageSourceTarget;

const GBALinkerScript = libRoot() ++ "/gba.ld";
const GBALibFile = libRoot() ++ "/gba.zig";

var is_debug: ?bool = null;
var UseGDBOption: ?bool = null;

const gba_thumb_target_query = blk: {
    var target = std.Target.Query{
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

pub fn addGBAStaticLibrary(b: *std.Build, libraryName: []const u8, sourceFile: []const u8, debug: bool) *std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = libraryName,
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = sourceFile } },
        .target = b.resolveTargetQuery(gba_thumb_target_query),
        .optimize = if (debug) .Debug else .ReleaseFast,
    });

    lib.setLinkerScriptPath(.{ .src_path = .{ .owner = b, .sub_path = GBALinkerScript } });

    return lib;
}

pub fn createGBALib(b: *std.Build, debug: bool) *std.Build.Step.Compile {
    return addGBAStaticLibrary(b, "ZigGBA", GBALibFile, debug);
}

pub fn addGBAExecutable(b: *std.Build, romName: []const u8, sourceFile: []const u8) *std.Build.Step.Compile {
    const debug = blk: {
        if (is_debug) |value| {
            break :blk value;
        } else {
            const new_dbg = b.option(bool, "debug", "Generate a debug build") orelse false;
            is_debug = new_dbg;
            break :blk new_dbg;
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
        .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = sourceFile } },
        .target = b.resolveTargetQuery(gba_thumb_target_query),
        .optimize = if (debug) .Debug else .ReleaseFast,
    });

    exe.setLinkerScriptPath(.{ .src_path = .{ .owner = b, .sub_path = GBALinkerScript } });
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

    const gbaLib = createGBALib(b, debug);
    exe.root_module.addAnonymousImport("gba", .{ .root_source_file = .{ .src_path = .{ .owner = b, .sub_path = GBALibFile } } });
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

    fn make(step: *Step, options: Step.MakeOptions) anyerror!void {
        const self: *Mode4ConvertStep = @fieldParentPtr("step", step);
        const ImageSourceTargetList = ArrayList(ImageSourceTarget);

        var fullImages = ImageSourceTargetList.init(step.owner.allocator);
        defer fullImages.deinit();

        var node = options.progress_node.start("Converting mode4 images", 1);
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

pub fn convertMode4Images(compile_step: *std.Build.Step.Compile, images: []const ImageSourceTarget, targetPalettePath: []const u8) void {
    const convertImageStep = compile_step.step.owner.allocator.create(Mode4ConvertStep) catch unreachable;
    convertImageStep.* = Mode4ConvertStep.init(compile_step.step.owner, images, targetPalettePath);
    compile_step.step.dependOn(&convertImageStep.step);
}
