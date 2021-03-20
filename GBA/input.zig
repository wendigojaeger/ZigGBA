const GBA = @import("core.zig").GBA;

pub const Input = struct {
    var previousInput: u16 = 0;
    var currentInput: u16 = 0;

    pub const Keys = struct {
        pub const A = 1 << 0;
        pub const B = 1 << 1;
        pub const Select = 1 << 2;
        pub const Start = 1 << 3;
        pub const Right = 1 << 4;
        pub const Left = 1 << 5;
        pub const Up = 1 << 6;
        pub const Down = 1 << 7;
        pub const R = 1 << 8;
        pub const L = 1 << 9;
    };

    pub const KeyIndex = enum {
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
        Count,
    };

    pub fn readInput() void {
        previousInput = currentInput;
        currentInput = ~GBA.REG_KEYINPUT.*;
    }

    pub fn isKeyDown(keys: u16) callconv(.Inline) bool {
        return (currentInput & keys) == keys;
    }

    pub fn isKeyHeld(keys: u16) callconv(.Inline) bool {
        return ((previousInput & currentInput) & keys) == keys;
    }

    pub fn isKeyJustPressed(keys: u16) callconv(.Inline) bool {
        return ((~previousInput & currentInput) & keys) == keys;
    }

    pub fn isKeyJustReleased(keys: u16) callconv(.Inline) bool {
        return ((previousInput & ~currentInput) & keys) == keys;
    }

    pub fn isKeyUp(keys: u16) callconv(.Inline) bool {
        return (currentInput & keys) == 0;
    }

    pub fn getHorizontal() callconv(.Inline) i32 {
        return triState(currentInput, KeyIndex.Left, KeyIndex.Right);
    }

    pub fn getVertical() callconv(.Inline) i32 {
        return triState(currentInput, KeyIndex.Up, KeyIndex.Down);
    }

    pub fn getShoulder() callconv(.Inline) i32 {
        return triState(currentInput, KeyIndex.L, KeyIndex.R);
    }

    pub fn getShoulderJustPressed() callconv(.Inline) i32 {
        return triState((~previousInput & currentInput), KeyIndex.L, KeyIndex.R);
    }

    pub fn triState(input: u16, minus: KeyIndex, plus: KeyIndex) callconv(.Inline) i32 {
        return ((@intCast(i32, input) >> @intCast(u5, @enumToInt(plus))) & 1) - ((@intCast(i32, input) >> @intCast(u5, @enumToInt(minus))) & 1);
    }
};
