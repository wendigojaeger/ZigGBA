//! Access to the key control and status registers should
//! go through the functions in this module.
//!
//! Keys are active low, which doesn't play well intuitively
//! with checking them. These functions abstract that conversion
const std = @import("std");

pub const Keys = std.EnumSet(Key);

var prev_input: Keys = .{};
var curr_input: Keys = .{};

const REG_KEYINPUT: *align(2) const volatile u10 = @ptrFromInt(0x4000130);

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
    const Condition = enum(u1) {
        Any = 0,
        All = 1,
    };

    keys: Keys,
    _: u4,
    interrupt: bool,
    op: Condition,
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
    pub fn get(axis: Axis) i4 {
        return switch (axis) {
            .Horizontal => triState(curr_input, .Left, .Right),
            .Vertical => triState(curr_input, .Up, .Down),
            .Shoulders => triState(curr_input, .L, .R),
        };
    }
};

fn pressedInt(input: Keys, key: Key) i4 {
    return @intFromBool(input.contains(key));
}

/// The keypad should always be read through this function, never directly.
pub fn poll() void {
    prev_input = curr_input;
    curr_input = .{ .bits = .{ .mask = ~REG_KEYINPUT.* } };
}

pub fn isKeyPressed(key: Key) bool {
    return curr_input.contains(key);
}

pub fn isKeyHeld(key: Key) bool {
    return curr_input.intersectWith(prev_input).contains(key);
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

pub fn triState(input: Keys, minus: Key, plus: Key) i4 {
    return pressedInt(input, plus) - pressedInt(input, minus);
}

test "Test Axis.get()" {
    curr_input = Keys.initOne(.Left);
    try std.testing.expectEqual(-1, Axis.Horizontal.get());
    curr_input.insert(.Right);
    try std.testing.expectEqual(0, Axis.Horizontal.get());
    curr_input.remove(.Left);
    try std.testing.expectEqual(1, Axis.get(.Horizontal));
    curr_input.remove(.Right);
    try std.testing.expectEqual(0, Axis.get(.Horizontal));
}