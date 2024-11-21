pub const Color = packed struct(u16) {
    pub const black = Color.rgb(0, 0, 0);
    pub const red = Color.rgb(31, 0, 0);
    pub const lime = Color.rgb(0, 31, 0);
    pub const yellow = Color.rgb(31, 31, 0);
    pub const blue = Color.rgb(0, 0, 31);
    pub const magenta = Color.rgb(31, 0, 31);
    pub const cyan = Color.rgb(0, 31, 31);
    pub const white = Color.rgb(31, 31, 31);

    r: u5 = 0,
    g: u5 = 0,
    b: u5 = 0,
    _: u1 = 0,

    pub fn rgb(r: u5, g: u5, b: u5) Color {
        return .{
            .r = r,
            .g = g,
            .b = b,
        };
    }

    /// A palette of 16 colors. The color at `bank[0]` is always transparent.
    pub const Bank = [16]Color;

    pub const Palette = union {
        banks: [16]Bank,
        full: [256]Color,
    };

    /// Determines whether palettes are accessed via banks of 16 colors
    /// or a single palette of 256 colors
    pub const Mode = enum(u1) {
        /// Palettes are stored in 16 banks of 16 colors, 4bpp
        color_16,
        /// Single palette of 256 colors, 8bpp
        color_256,
    };
};
