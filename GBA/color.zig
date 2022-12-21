const GBA = @import("core.zig").GBA;

pub const Color = struct {
    pub const Black = GBA.toNativeColor(0, 0, 0);
    pub const Red = GBA.toNativeColor(31, 0, 0);
    pub const Lime = GBA.toNativeColor(0, 31, 0);
    pub const Yellow = GBA.toNativeColor(31, 31, 0);
    pub const Blue = GBA.toNativeColor(0, 0, 31);
    pub const Magenta = GBA.toNativeColor(31, 0, 31);
    pub const Cyan = GBA.toNativeColor(0, 31, 31);
    pub const While = GBA.toNativeColor(31, 31, 31);
};
