const std = @import("std");

var prev_input: Keys = Keys.initEmpty();
/// The keypad should always be read through this variable, never directly.
var curr_input: Keys = Keys.initEmpty();

const REG_KEYINPUT: *align(2) volatile const u10 = @ptrFromInt(0x4000130);

pub const Key = enum {
    A,
    B,
    Select,
    Start,
    Right,
    Left,
    Up,
    Down,
    R,
    L,
};

pub const KeyCtrl = packed struct(u16) {
    const Op = enum(u1) {
        Or = 0,
        And = 1,
    };

    keys: Keys,
    _: u4,
    interrupt: bool,
    op: Op,
};

/// Allows reading the D-pad and shoulders as connected axes
/// that can be read as -1, 0, or 1. 
/// 
/// Negative axes are Left, Up, and L.
pub const Axis = enum {
    Horizontal,
    Vertical,
    Shoulders,

    /// Get the current value of this axis. Returns 0 if both buttons
    /// or neither are pressed.
    pub fn get(axis: Axis) i2 {
        return switch (axis) {
            .Horizontal => triState(curr_input, .Left, .Right),
            .Vertical => triState(curr_input, .Up, .Down),
            .Shoulders => triState(curr_input, .L, .R),
        };
    }
};

pub const Keys = std.EnumSet(Key);

fn pressedInt(input: Keys, key: Key) i2 {
    return @intFromBool(input.contains(key));
}

pub fn pollInput() void {
    prev_input = curr_input;
    curr_input = .{.bits = .{ .mask = ~REG_KEYINPUT.*}};
}

pub fn isKeyChanged(key: Key) bool {
    return prev_input.xorWith(curr_input).contains(key);
}

pub fn isComboPressed(combo: Keys) bool {
    return combo.subsetOf(curr_input);
}

pub fn isComboHeld(combo: Keys) bool {
    return combo.subsetOf(curr_input.intersectWith(prev_input));
}

pub fn isAnyJustPressed(keys: Keys) bool {
    return curr_input.differenceWith(prev_input).intersectWith(keys).eql(Keys.initEmpty());
}

pub fn isKeyJustPressed(key: Key) bool {
    return curr_input.differenceWith(prev_input).contains(key);
}

pub fn isKeyJustReleased(key: Key) bool {
    return prev_input.differenceWith(curr_input).contains(key);
}

pub fn triState(input: Keys, minus: Key, plus: Key) u2 {
    return pressedInt(input, plus) - pressedInt(input, minus);
}

test "Test Axis.get()" {
    curr_input = Keys.initOne(.Left);
    try std.testing.expectEqual(-1, Axis.Horizontal.get());
    curr_input.insert(.Right);
    try std.testing.expectEqual(0, Axis.Horizontal.get());
    curr_input.remove(.Left);
    try std.testing.expectEqual(1, Axis.Horizontal.get());
    curr_input.remove(.Right);
    try std.testing.expectEqual(0, Axis.Horizontal.get());
}