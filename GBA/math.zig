const std = @import("std");
const builtin = std.builtin;
const TypeInfo = builtin.TypeInfo;
const alignForward = std.mem.alignForward;
const pi = std.math.pi;

pub const Math = struct {
    pub fn FixedPoint(comptime isSigned: bool, comptime integral_size: comptime_int, comptime fractional_size: comptime_int) type {
        return packed struct {
            raw: RawType = undefined,

            const SignedRawType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .is_signed = true, .bits = integral_size + fractional_size } });
            const UnsignedRawType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .is_signed = false, .bits = integral_size + fractional_size } });
            const RawType = if (isSigned) SignedRawType else UnsignedRawType;

            const SignedAlignIntegerType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .is_signed = true, .bits = alignForward(integral_size + fractional_size, 8) } });
            const UnsignedAlignIntegerType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .is_signed = false, .bits = alignForward(integral_size + fractional_size, 8) } });
            const AlignIntegerType = if (isSigned) SignedAlignIntegerType else UnsignedAlignIntegerType;

            const InputIntegerType = @Type(TypeInfo{ .Int = TypeInfo.Int{ .is_signed = isSigned, .bits = integral_size } });

            const MaxIntegerType = if (isSigned) i32 else u32;

            pub const Shift = fractional_size;
            pub const Scale = 1 << fractional_size;
            pub const IntegralMask = (1 << integral_size) - 1;
            pub const FractionalMask = (1 << fractional_size) - 1;

            const Self = @This();

            pub inline fn fromInt(value: InputIntegerType) Self {
                return Self{
                    .raw = @as(RawType, @truncate(@as(AlignIntegerType, @intCast(value)) << Shift)),
                };
            }

            pub inline fn fromF32(comptime value: f32) Self {
                return Self{
                    .raw = @as(RawType, @intFromFloat(value * Scale)),
                };
            }

            pub inline fn setInt(self: *Self, value: InputIntegerType) void {
                self.raw = fromInt(value).raw;
            }

            pub inline fn setF32(self: *Self, comptime value: f32) void {
                self.raw = fromF32(value).raw;
            }

            pub inline fn integral(self: Self) UnsignedAlignIntegerType {
                return @as(UnsignedAlignIntegerType, @intCast((@as(UnsignedRawType, @bitCast(self.raw)) >> Shift) & (IntegralMask)));
            }

            pub inline fn fractional(self: Self) UnsignedAlignIntegerType {
                return @as(UnsignedAlignIntegerType, @intCast(@as(UnsignedRawType, @bitCast(self.raw)) & FractionalMask));
            }

            pub inline fn toF32(self: Self) f32 {
                return @as(f32, @floatFromInt(self.raw)) / Scale;
            }

            pub inline fn add(left: Self, right: Self) Self {
                return Self{
                    .raw = left.raw + right.raw,
                };
            }

            pub inline fn addSelf(left: *Self, right: Self) void {
                left.raw = add(left, right).raw;
            }

            pub inline fn sub(left: Self, right: Self) Self {
                return Self{
                    .raw = left.raw - right.raw,
                };
            }

            pub inline fn subSelf(left: *Self, right: Self) void {
                left.raw = sub(left, right).raw;
            }

            pub inline fn mul(left: Self, right: Self) Self {
                return Self{
                    .raw = @as(RawType, @truncate((@as(MaxIntegerType, @intCast(left.raw)) * @as(MaxIntegerType, @intCast(right.raw))) >> Shift)),
                };
            }

            pub inline fn mulSelf(left: *Self, right: Self) void {
                left.raw = mul(left, right).raw;
            }

            pub inline fn div(left: Self, right: Self) Self {
                return Self{
                    .raw = @as(RawType, @truncate(@divTrunc(@as(MaxIntegerType, @intCast(left.raw)) * Scale, @as(MaxIntegerType, @intCast(right.raw))))),
                };
            }

            pub inline fn divSelf(left: *Self, right: Self) void {
                left.raw = div(left, right).raw;
            }

            pub const toInt = if (isSigned) toIntSigned else toIntUnsigned;

            fn toIntUnsigned(self: Self) AlignIntegerType {
                return self.raw >> Shift;
            }

            fn toIntSigned(self: Self) AlignIntegerType {
                return @divFloor(self.raw, Scale);
            }
        };
    }

    pub const FixedI8_8 = FixedPoint(true, 8, 8);
    pub const FixedU8_8 = FixedPoint(false, 8, 8);

    pub const FixedI4_12 = FixedPoint(true, 4, 12);
    pub const FixedU4_12 = FixedPoint(false, 4, 12);

    pub const FixedI19_8 = FixedPoint(true, 19, 8);
    pub const FixedU19_8 = FixedPoint(false, 19, 8);

    pub const sin_lut: [512]i16 = blk: {
        @setEvalBranchQuota(10000);
        var result: [512]i16 = undefined;

        var i: usize = 0;
        while (i < result.len) : (i += 1) {
            const sinValue = std.math.sin(@as(f32, @floatFromInt(i)) * 2.0 * pi / 512.0);
            const fixedValue = FixedI4_12.fromF32(sinValue);

            result[i] = fixedValue.raw;
        }
        break :blk result;
    };

    pub fn sin(theta: i32) FixedI4_12 {
        return FixedI4_12{
            .raw = sin_lut[@as(u32, @bitCast((theta >> 7) & 0x1FF))],
        };
    }

    pub fn cos(theta: i32) FixedI4_12 {
        return FixedI4_12{
            .raw = sin_lut[@as(u32, @bitCast(((theta >> 7) + 128) & 0x1FF))],
        };
    }

    pub inline fn degreeToGbaAngle(comptime input: i32) i32 {
        return @as(i32, @intFromFloat(@as(f32, @floatFromInt(input)) * ((1 << 16) / 360.0)));
    }

    pub inline fn radianToGbaAngle(comptime input: f32) i32 {
        return @as(i32, @intFromFloat(input * ((1 << 16) / (std.math.tau))));
    }
};
