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
        gameBoyColorMode: bool = false,
        pageSelect: u1 = 0,
        oamAccessDuringHBlank: bool = false,
        objVramCharacterMapping: ObjCharacterMapping = .TwoDimension,
        forcedBlank: bool = false,
        backgroundLayer0: Visiblity = .Hide,
        backgroundLayer1: Visiblity = .Hide,
        backgroundLayer2: Visiblity = .Hide,
        backgroundLayer3: Visiblity = .Hide,
        objectLayer: Visiblity = .Hide,
        showWindow0: Visiblity = .Hide,
        showWindow1: Visiblity = .Hide,
        showObjWindow: Visiblity = .Hide,
    };

    const gbaDisplayControl = @ptrCast(*volatile DisplayControl, GBA.REG_DISPCNT);

    pub fn setupDisplayControl(displaySettings: DisplayControl) callconv(.Inline) void {
        gbaDisplayControl.* = displaySettings;
    }

    pub fn changeObjVramCharacterMapping(objVramCharacterMapping: ObjCharacterMapping) callconv(.Inline) void {
        gbaDisplayControl.objVramCharacterMapping = objVramCharacterMapping;
    }

    pub fn pageFlip() callconv(.Inline) [*]volatile u16 {
        currentPage = @intToPtr([*]volatile u16, @as(u32, @ptrToInt(currentPage)) ^ Mode4PageSize);
        gbaDisplayControl.pageSelect = ~gbaDisplayControl.pageSelect;
        return currentPage;
    }

    pub fn naiveVSync() callconv(.Inline) void {
        while (GBA.REG_VCOUNT.* >= 160) {} // wait till VDraw
        while (GBA.REG_VCOUNT.* < 160) {} // wait till VBlank
    }
};
