const GBA = @import("core.zig").GBA;

pub const LCD = struct {
    var currentPage = GBA.MODE4_BACK_VRAM;

    const Mode4PageSize = 0xA000;

    pub const DisplayMode = enum {
        Mode0,
        Mode1,
        Mode2,
        Mode3,
        Mode4,
        Mode5,
    };

    pub const DisplayControl = struct {
        pub const PageSelect = 1 << 4;
    };

    pub const DisplayLayers = struct {
        pub const Background0 = 0x0100;
        pub const Background1 = 0x0200;
        pub const Background2 = 0x0400;
        pub const Background3 = 0x0800;
        pub const Object = 0x1000;
    };

    pub inline fn setupDisplay(mode: DisplayMode, layers: u32) void {
        GBA.REG_DISPCNT.* = @enumToInt(mode) | layers;
    }

    /// Flip Mode 4 page and return the writtable page
    pub inline fn pageFlip() [*]volatile u16 {
        currentPage = @intToPtr([*]volatile u16, @as(u32, @ptrToInt(currentPage)) ^ Mode4PageSize);
        GBA.REG_DISPCNT.* ^= DisplayControl.PageSelect;
        return currentPage;
    }

    pub inline fn naiveVSync() void {
        while (GBA.REG_VCOUNT.* >= 160) {} // wait till VDraw
        while (GBA.REG_VCOUNT.* < 160) {} // wait till VBlank
    }
};
