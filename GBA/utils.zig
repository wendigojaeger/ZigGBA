pub const Enable = enum(u1) {
    disable,
    enable,

    /// Convenience function for initializing based on a condition
    pub fn init(value: bool) Enable {
        return @enumFromInt(@intFromBool(value));
    }

    pub fn toggle(self: Enable) Enable {
        return @enumFromInt(@intFromEnum(self) ^ 1);
    }

    pub fn enabled(self: Enable) bool {
        return self == .enable;
    }
};

/// Ternary primitive
pub const TriState = enum(i2) {
    minus = -1,
    zero = 0,
    plus = 1,

    pub fn get(minus: bool, plus: bool) TriState {
        return @enumFromInt(@as(i2, @intCast(@intFromBool(plus))) - @intFromBool(minus));
    }

    pub fn toInt(self: TriState) i2 {
        return @intFromEnum(self);
    }

    pub fn scale(self: TriState, amt: anytype) @TypeOf(amt) {
        return amt * self.toInt();
    }
};
