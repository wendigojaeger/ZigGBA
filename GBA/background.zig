const GBA = @import("core.zig").GBA;

pub const Background = struct {
    pub const Palette: [*]GBA.PaletteBank = @ptrFromInt(@intFromPtr(GBA.BG_PALETTE_RAM));

    pub const BackgroundControl = packed struct {
        priority: u2 = 0,
        characterBaseBlock: u2 = 0,
        dummy: u2 = 0,
        mosaic: bool = false,
        paletteMode: GBA.PaletteMode = .Color16,
        screenBaseBlock: u5 = 0,
        dummy2: u1 = 0,
        screenSize: enum(u2) {
            Text32x32,
            Text64x32,
            Text32x64,
            Text64x64,
        } = .Text32x32,
    };

    pub const Background0Control: *volatile BackgroundControl = @ptrFromInt(0x4000008);
    pub const Background1Control: *volatile BackgroundControl = @ptrFromInt(0x400000A);
    pub const Background2Control: *volatile BackgroundControl = @ptrFromInt(0x400000C);
    pub const Background3Control: *volatile BackgroundControl = @ptrFromInt(0x400000E);

    pub inline fn setupBackground(background: *volatile BackgroundControl, settings: BackgroundControl) void {
        background.* = settings;
    }

    pub const Scroll = packed struct {
        x: u9 = 0,
        dummy: u7 = 0,
        y: u9 = 0,
        dummy2: u7 = 0,

        const Self = @This();
        pub inline fn setPosition(self: *volatile Self, x: i32, y: i32) void {
            @setRuntimeSafety(false);
            const Mask = (1 << 9) - 1;
            self.x = @intCast(x & Mask);
            self.y = @intCast(y & Mask);
        }
    };

    pub const Background0Scroll: *volatile Scroll = @ptrFromInt(0x4000010);
    pub const Background1Scroll: *volatile Scroll = @ptrFromInt(0x4000014);
    pub const Background2Scroll: *volatile Scroll = @ptrFromInt(0x4000018);
    pub const Background3Scroll: *volatile Scroll = @ptrFromInt(0x400001C);

    pub const TextScreenEntry = packed struct {
        tileIndex: u10 = 0,
        horizontalFlip: bool = false,
        verticalFlip: bool = false,
        paletteIndex: u4 = 0,
    };

    pub const AffineScreenEntry = packed struct {
        tileIndex: u8 = 0,
    };

    pub const TextScreenBlock = [1024]TextScreenEntry;
    pub const ScreenBlockMemory: [*]align(4) volatile TextScreenBlock = @ptrFromInt(@intFromPtr(GBA.VRAM));

    pub const Tile = extern struct { data: [8]u32 align(1) };

    pub const CharacterBlock = [512]Tile;
    pub const TileMemory: [*]align(4) volatile CharacterBlock = @ptrFromInt(@intFromPtr(GBA.VRAM));

    pub const Tile8 = extern struct { data: [16]u32 align(1) };

    pub const CharacterBlock8 = [256]Tile8;
    pub const Tile8Memory: [*]align(4) volatile CharacterBlock8 = @ptrFromInt(@intFromPtr(GBA.VRAM));
};
