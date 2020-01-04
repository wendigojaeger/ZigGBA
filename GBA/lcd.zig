const GBA = @import("core.zig").GBA;

pub const LCD = struct {
    var currentPage = GBA.MODE4_BACK_VRAM;

    const Mode4PageSize = 0xA000;

    pub const DisplayMode = enum(u3) {
        Mode0,
        Mode1,
        Mode2,
        Mode3,
        Mode4,
        Mode5,
    };

    pub const ObjCharacterMapping = enum(u1) {
        TwoDimension,
        OneDimension,
    };

    pub const Visiblity = enum(u1) {
        Hide,
        Show,
    };

    pub const DisplayControl = packed struct {
        mode: DisplayMode = .Mode0,
        gameBoyColorMode: u1 = 0,
        pageSelect: u1 = 0,
        oamAccessDuringHBlank: u1 = 0,
        objVramCharacterMapping: ObjCharacterMapping = .TwoDimension,
        forcedBlank: u1 = 0,
        backgroundLayer0: Visiblity = .Hide,
        backgroundLayer1: Visiblity = .Hide,
        backgroundLayer2: Visiblity = .Hide,
        backgroundLayer3: Visiblity = .Hide,
        objectLayer: Visiblity = .Hide,
        showWindow0: Visiblity = .Hide,
        showWindow1: Visiblity = .Hide,
        showObjWindow: Visiblity = .Hide,
    };

    const gbaDisplayControl = @ptrCast(*DisplayControl, GBA.REG_DISPCNT);

    pub inline fn setupDisplayControl(displaySettings: DisplayControl) void {
        gbaDisplayControl.* = displaySettings;
    }

    pub inline fn changeObjVramCharacterMapping(objVramCharacterMapping: ObjCharacterMapping) void {
        gbaDisplayControl.objVramCharacterMapping = objVramCharacterMapping;
    }

    /// Flip Mode 4 page and return the writtable page
    pub inline fn pageFlip() [*]volatile u16 {
        currentPage = @intToPtr([*]volatile u16, @as(u32, @ptrToInt(currentPage)) ^ Mode4PageSize);
        gbaDisplayControl.pageSelect = ~gbaDisplayControl.pageSelect;
        return currentPage;
    }

    pub inline fn naiveVSync() void {
        while (GBA.REG_VCOUNT.* >= 160) {} // wait till VDraw
        while (GBA.REG_VCOUNT.* < 160) {} // wait till VBlank
    }
};
