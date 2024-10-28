pub const Color = packed struct(u16) {
    pub const Black = Color.rgb(0, 0, 0);
    pub const Red = Color.rgb(31, 0, 0);
    pub const Lime = Color.rgb(0, 31, 0);
    pub const Yellow = Color.rgb(31, 31, 0);
    pub const Blue = Color.rgb(0, 0, 31);
    pub const Magenta = Color.rgb(31, 0, 31);
    pub const Cyan = Color.rgb(0, 31, 31);
    pub const White = Color.rgb(31, 31, 31);

    r: u5,
    g: u5,
    b: u5,

    pub fn rgb(r: u5, g: u5, b: u5) Color {
        return .{
            .r = r,
            .g = g,
            .b = b,
        };
    }
};
