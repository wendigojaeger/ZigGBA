const std = @import("std");
const Signedness = std.builtin.Signedness;
const Int = std.meta.Int;

/// Fixed point integer type
pub fn FixedPoint(comptime signedness: Signedness, comptime integral_bits: comptime_int, comptime fractional_bits: comptime_int) type {
    const RawType = Int(signedness, integral_bits + fractional_bits);
    return packed struct(RawType) {
        const Self = @This();

        const FractionalType = Int(signedness, fractional_bits);
        const IntegralType = Int(signedness, integral_bits);
        const MaxIntegerType = Int(signedness, 32);
        
        pub const scale = 1 << fractional_bits;

        fractional: FractionalType = 0,
        integral: IntegralType = 0,

        pub fn raw(self: Self) RawType {
            return @bitCast(self);
        }

        pub fn eql(lhs: Self, rhs: Self) bool {
            return lhs.raw() == rhs.raw();
        }

        /// Takes an integer and returns a fixed point number with that integer as its integral value.
        pub fn fromInt(value: IntegralType) Self {
            return .{ .integral = value };
        }

        pub fn fromF32(comptime value: f32) Self {
            return @bitCast(@as(RawType, @intFromFloat(value * scale)));
        }

        pub fn setInt(self: *Self, value: IntegralType) void {
            self.* = fromInt(value);
        }

        pub fn setF32(self: *Self, comptime value: f32) void {
            self.* = fromF32(value);
        }

        pub fn toF32(self: Self) f32 {
            return @as(f32, @floatFromInt(self.raw())) / scale;
        }

        pub fn add(left: Self, right: Self) Self {
            return @bitCast(left.raw() + right.raw());
        }

        pub fn setAdd(left: *Self, right: Self) void {
            left.* = add(left.*, right);
        }

        pub fn sub(left: Self, right: Self) Self {
            return @bitCast(left.raw() - right.raw());
        }

        pub fn setSub(left: *Self, right: Self) void {
            left.* = sub(left.*, right);
        }

        pub fn toInt32(self: Self) MaxIntegerType {
            return @as(MaxIntegerType, @intCast(self.raw()));
        }

        pub fn mul(left: Self, right: Self) Self {
            return @bitCast(@as(RawType, @truncate((left.toInt32() * right.toInt32()) >> fractional_bits)));
        }

        pub fn setMul(left: *Self, right: Self) void {
            left.* = mul(left.*, right);
        }

        pub fn div(left: Self, right: Self) Self {
            return @bitCast(@as(RawType, @truncate(@divTrunc(left.toInt32() * scale, right.toInt32()))));
        }

        pub fn setDiv(left: *Self, right: Self) void {
            left.* = div(left.*, right);
        }

        const ToIntType = if (@sizeOf(RawType) <= 2) RawType else MaxIntegerType;

        pub fn toInt(self: Self) ToIntType {
            return @as(ToIntType, @intCast(self.integral));
        }
    };
}

pub const FixedI8_8 = FixedPoint(.signed, 8, 8);
pub const FixedU8_8 = FixedPoint(.unsigned, 8, 8);

pub const FixedI4_12 = FixedPoint(.signed, 4, 12);
pub const FixedU4_12 = FixedPoint(.unsigned, 4, 12);

pub const FixedI19_8 = FixedPoint(.signed, 19, 8);
pub const FixedU19_8 = FixedPoint(.unsigned, 19, 8);

pub const sin_lut: [512]FixedI4_12 = blk: {
    @setEvalBranchQuota(10000);
    var result: [512]FixedI4_12 = undefined;

    var i: usize = 0;
    while (i < result.len) : (i += 1) {
        const sinValue = std.math.sin(@as(f32, @floatFromInt(i)) * std.math.tau / 512.0);
        result[i] = FixedI4_12.fromF32(sinValue);
    }
    break :blk result;
};

pub fn sin(theta: i32) FixedI4_12 {
    return sin_lut[@as(u32, @bitCast((theta >> 7) & 0x1FF))];
}

pub fn cos(theta: i32) FixedI4_12 {
    return sin_lut[@as(u32, @bitCast(((theta >> 7) + 128) & 0x1FF))];
}

pub fn degreeToGbaAngle(comptime input: i32) i32 {
    return @as(i32, @intFromFloat(@as(f32, @floatFromInt(input)) * ((1 << 16) / 360.0)));
}

pub fn radianToGbaAngle(comptime input: f32) i32 {
    return @as(i32, @intFromFloat(input * ((1 << 16) / (std.math.tau))));
}
