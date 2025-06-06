const gba = @import("gba");
const Enable = gba.utils.Enable;

export const gameHeader linksection(".gbaheader") = gba.initHeader("JESUMUSIC", "AJME", "00", 0);

// Must be aligned or else memcpy will copy a byte at a time,
// and VRAM doesn't like that.
// https://github.com/Games-by-Mason/SPIRV-Reflect-zig/pull/1#issuecomment-2655358098
/// File contains tile image data.
const charset_data align(4) = @embedFile("charset.bin").*;

const hex_digits: [16]u8 = .{
    '0', '1', '2', '3', '4', '5', '6', '7',
    '8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
};

const Pitch = enum(u8) {
    C_2 = 0x0,
    Cs2 = 0x1,
    D_2 = 0x2,
    Ds2 = 0x3,
    E_2 = 0x4,
    F_2 = 0x5,
    Fs2 = 0x6,
    G_2 = 0x7,
    Gs2 = 0x8,
    A_2 = 0x9,
    As2 = 0xa,
    B_2 = 0xb,
    C_3 = 0xc,
    Cs3 = 0xd,
    D_3 = 0xe,
    Ds3 = 0xf,
    E_3 = 0x10,
    F_3 = 0x11,
    Fs3 = 0x12,
    G_3 = 0x13,
    Gs3 = 0x14,
    A_3 = 0x15,
    As3 = 0x16,
    B_3 = 0x17,
    C_4 = 0x18,
    Cs4 = 0x19,
    D_4 = 0x1a,
    Ds4 = 0x1b,
    E_4 = 0x1c,
    F_4 = 0x1d,
    Fs4 = 0x1e,
    G_4 = 0x1f,
    Gs4 = 0x20,
    A_4 = 0x21,
    As4 = 0x22,
    B_4 = 0x23,
    C_5 = 0x24,
    Cs5 = 0x25,
    D_5 = 0x26,
    Ds5 = 0x27,
    E_5 = 0x28,
    F_5 = 0x29,
    Fs5 = 0x2a,
    G_5 = 0x2b,
    Gs5 = 0x2c,
    A_5 = 0x2d,
    As5 = 0x2e,
    B_5 = 0x2f,
    C_6 = 0x30,
    Cs6 = 0x31,
    D_6 = 0x32,
    Ds6 = 0x33,
    E_6 = 0x34,
    F_6 = 0x35,
    Fs6 = 0x36,
    G_6 = 0x37,
    Gs6 = 0x38,
    A_6 = 0x39,
    As6 = 0x3a,
    B_6 = 0x3b,
    C_7 = 0x3c,
    Cs7 = 0x3d,
    D_7 = 0x3e,
    Ds7 = 0x3f,
    E_7 = 0x40,
    F_7 = 0x41,
    Fs7 = 0x42,
    G_7 = 0x43,
    Gs7 = 0x44,
    A_7 = 0x45,
    As7 = 0x46,
    B_7 = 0x47,
    C_8 = 0x48,
    Cs8 = 0x49,
    D_8 = 0x4a,
    Ds8 = 0x4b,
    E_8 = 0x4c,
    F_8 = 0x4d,
    Fs8 = 0x4e,
    G_8 = 0x4f,
    Gs8 = 0x50,
    A_8 = 0x51,
    As8 = 0x52,
    B_8 = 0x53,

    /// Table of pulse channel rates corresponding to musical notes.
    /// Rates are computed as `round(2048 - ((2**17) / hz))`.
    const rates: [0x54]u11 = .{
        0x002c, // C-2 | 65.41 Hz
        0x009d, // C#2 | 69.30 Hz
        0x0107, // D-2 | 73.42 Hz
        0x016b, // D#2 | 77.78 Hz
        0x01ca, // E-2 | 82.41 Hz
        0x0223, // F-2 | 87.31 Hz
        0x0277, // F#2 | 92.50 Hz
        0x02c7, // G-2 | 98 Hz
        0x0312, // G#2 | 103.83 Hz
        0x0358, // A-2 | 110 Hz
        0x039b, // A#2 | 116.54 Hz
        0x03da, // B-2 | 123.47 Hz
        0x0416, // C-3 | 130.81 Hz
        0x044e, // C#3 | 138.59 Hz
        0x0483, // D-3 | 146.83 Hz
        0x04b5, // D#3 | 155.56 Hz
        0x04e5, // E-3 | 164.81 Hz
        0x0511, // F-3 | 174.61 Hz
        0x053c, // F#3 | 185 Hz
        0x0563, // G-3 | 196 Hz
        0x0589, // G#3 | 207.65 Hz
        0x05ac, // A-3 | 220 Hz
        0x05ce, // A#3 | 233.08 Hz
        0x05ed, // B-3 | 246.94 Hz
        0x060b, // C-4 | 261.63 Hz
        0x0627, // C#4 | 277.18 Hz
        0x0642, // D-4 | 293.66 Hz
        0x065b, // D#4 | 311.13 Hz
        0x0672, // E-4 | 329.63 Hz
        0x0689, // F-4 | 349.23 Hz
        0x069e, // F#4 | 369.99 Hz
        0x06b2, // G-4 | 392 Hz
        0x06c4, // G#4 | 415.30 Hz
        0x06d6, // A-4 | 440 Hz
        0x06e7, // A#4 | 466.16 Hz
        0x06f7, // B-4 | 493.88 Hz
        0x0706, // C-5 | 523.25 Hz
        0x0714, // C#5 | 554.37 Hz
        0x0721, // D-5 | 587.33 Hz
        0x072d, // D#5 | 622.25 Hz
        0x0739, // E-5 | 659.25 Hz
        0x0744, // F-5 | 698.46 Hz
        0x074f, // F#5 | 739.99 Hz
        0x0759, // G-5 | 783.99 Hz
        0x0762, // G#5 | 830.61 Hz
        0x076b, // A-5 | 880 Hz
        0x0773, // A#5 | 932.33 Hz
        0x077b, // B-5 | 987.77 Hz
        0x0783, // C-6 | 1046.50 Hz
        0x078a, // C#6 | 1108.73 Hz
        0x0790, // D-6 | 1174.66 Hz
        0x0797, // D#6 | 1244.51 Hz
        0x079d, // E-6 | 1318.51 Hz
        0x07a2, // F-6 | 1396.91 Hz
        0x07a7, // F#6 | 1479.98 Hz
        0x07ac, // G-6 | 1567.98 Hz
        0x07b1, // G#6 | 1661.22 Hz
        0x07b6, // A-6 | 1760 Hz
        0x07ba, // A#6 | 1864.66 Hz
        0x07be, // B-6 | 1975.53 Hz
        0x07c1, // C-7 | 2093.00 Hz
        0x07c5, // C#7 | 2217.46 Hz
        0x07c8, // D-7 | 2349.32 Hz
        0x07cb, // D#7 | 2489.02 Hz
        0x07ce, // E-7 | 2637.02 Hz
        0x07d1, // F-7 | 2793.83 Hz
        0x07d4, // F#7 | 2959.96 Hz
        0x07d6, // G-7 | 3135.96 Hz
        0x07d9, // G#7 | 3322.44 Hz
        0x07db, // A-7 | 3520 Hz
        0x07dd, // A#7 | 3729.31 Hz
        0x07df, // B-7 | 3951.07 Hz
        0x07e1, // C-8 | 4186.01 Hz
        0x07e2, // C#8 | 4434.92 Hz
        0x07e4, // D-8 | 4698.63 Hz
        0x07e6, // D#8 | 4978.03 Hz
        0x07e7, // E-8 | 5274.04 Hz
        0x07e9, // F-8 | 5587.65 Hz
        0x07ea, // F#8 | 5919.91 Hz
        0x07eb, // G-8 | 6271.93 Hz
        0x07ec, // G#8 | 6644.88 Hz
        0x07ed, // A-8 | 7040 Hz
        0x07ee, // A#8 | 7458.62 Hz
        0x07ef, // B-8 | 7902.13 Hz
    };

    const names: [84][]const u8 = .{
        "C-2", "C#2", "D-2", "D#2", "E-2", "F-2",
        "F#2", "G-2", "G#2", "A-2", "A#2", "B-2",
        "C-3", "C#3", "D-3", "D#3", "E-3", "F-3",
        "F#3", "G-3", "G#3", "A-3", "A#3", "B-3",
        "C-4", "C#4", "D-4", "D#4", "E-4", "F-4",
        "F#4", "G-4", "G#4", "A-4", "A#4", "B-4",
        "C-5", "C#5", "D-5", "D#5", "E-5", "F-5",
        "F#5", "G-5", "G#5", "A-5", "A#5", "B-5",
        "C-6", "C#6", "D-6", "D#6", "E-6", "F-6",
        "F#6", "G-6", "G#6", "A-6", "A#6", "B-6",
        "C-7", "C#7", "D-7", "D#7", "E-7", "F-7",
        "F#7", "G-7", "G#7", "A-7", "A#7", "B-7",
        "C-8", "C#8", "D-8", "D#8", "E-8", "F-8",
        "F#8", "G-8", "G#8", "A-8", "A#8", "B-8",
    };

    pub fn rate(pitch: Pitch) u11 {
        return rates[@intFromEnum(pitch)];
    }

    pub fn name(pitch: Pitch) []const u8 {
        return names[@intFromEnum(pitch)];
    }

    pub fn transpose(pitch: Pitch, semitones: i8) Pitch {
        return @enumFromInt(@intFromEnum(pitch) +% @as(u8, @bitCast(semitones)));
    }
};

/// Constant used as the tempo value for each track.
const track_tempo: u8 = 0x18;

const OpCode = union(enum(u8)) {
    /// Opcode for music track bytecode, to be followed by an operand:
    /// Wait N frames * tempo before the next command.
    hold: u8 = 0,
    /// Opcode for music track bytecode, to be followed by an operand:
    /// Begin playing a note with a given pitch.
    note: Pitch = 1,
    /// Opcode for music track bytecode, to be followed by an operand:
    /// Set the volume of subsequent notes.
    volume: u4 = 2,
    /// Opcode for music track bytecode, to be followed by an operand:
    /// Set the volume envelope decay step of subsequent note.
    decay: u3 = 3,
    /// Opcode for music track bytecode, to be followed by an operand:
    /// Transpose the pitch of subsequent notes. Adds to pitch.
    transpose: i8 = 4,
    /// Opcode for music track bytecode, to be followed by an operand:
    /// Set the frame intervals used by op_hold commands.
    tempo: u8 = 6,
    /// Opcode for music track bytecode, to be followed by an operand:
    /// Set duty on pulse channels.
    duty: gba.sound.PulseDuty = 7,
    /// Opcode for music track bytecode, to be followed by an operand:
    /// Jump to another command in the bytecode.
    goto: u8 = 8,

    pub fn operandAsByte(self: OpCode) u8 {
        return switch (self) {
            .hold, .goto, .tempo => |op| op,
            .note => |note| @intFromEnum(note),
            .volume => |vol| vol,
            .decay => |decay| decay,
            .transpose => |semitones| @bitCast(semitones),
            .duty => |duty| @intFromEnum(duty),
        };
    }

    fn tileIndex(self: OpCode) u10 {
        return 0x10 + @intFromEnum(self) + switch (self) {
            .transpose => |semitones| @intFromBool(semitones < 0),
            else => 0,
        };
    }
};

// zig fmt: off
/// Track bytecode for channel 1.
const track_data_pulse_1: []const OpCode = &.{
    .{ .volume = 0xf },
    .{ .decay = 0x4 },
    .{ .transpose = 0 },
    .{ .tempo = track_tempo },
    .{ .duty = .cycle_1_4 },
    .{ .note = .B_3 }, .{ .hold = 1 }, // 00
    .{ .note = .G_3 }, .{ .hold = 1 },
    .{ .note = .A_3 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .C_4 }, .{ .hold = 1 },
    .{ .note = .C_4 }, .{ .hold = 1 },
    .{ .note = .E_4 }, .{ .hold = 1 },
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .G_4 }, .{ .hold = 1 },
    .{ .note = .Fs4 }, .{ .hold = 1 },
    .{ .note = .G_4 }, .{ .hold = 1 }, // 0c
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .G_3 }, .{ .hold = 1 },
    .{ .note = .A_3 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .C_4 }, .{ .hold = 1 },
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .E_4 }, .{ .hold = 1 },
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .C_4 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .A_3 }, .{ .hold = 1 }, // 18
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .G_3 }, .{ .hold = 1 },
    .{ .note = .Fs3 }, .{ .hold = 1 },
    .{ .note = .G_3 }, .{ .hold = 1 },
    .{ .note = .A_3 }, .{ .hold = 1 },
    .{ .note = .D_3 }, .{ .hold = 1 },
    .{ .note = .Fs3 }, .{ .hold = 1 },
    .{ .note = .A_3 }, .{ .hold = 1 },
    .{ .note = .C_4 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .A_3 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 }, // 24
    .{ .note = .G_3 }, .{ .hold = 1 },
    .{ .note = .A_3 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .C_4 }, .{ .hold = 1 },
    .{ .note = .C_4 }, .{ .hold = 1 },
    .{ .note = .E_4 }, .{ .hold = 1 },
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .G_4 }, .{ .hold = 1 },
    .{ .note = .Fs4 }, .{ .hold = 1 },
    .{ .note = .G_4 }, .{ .hold = 1 }, // 30
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .G_3 }, .{ .hold = 1 },
    .{ .note = .A_3 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .E_3 }, .{ .hold = 1 },
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .C_4 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .A_3 }, .{ .hold = 1 },
    .{ .note = .G_3 }, .{ .hold = 1 },
    .{ .note = .D_3 }, .{ .hold = 1 }, // 3c
    .{ .note = .G_3 }, .{ .hold = 1 },
    .{ .note = .Fs3 }, .{ .hold = 1 },
    .{ .note = .G_3 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .G_4 }, .{ .hold = 1 },
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .G_3 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .G_4 }, .{ .hold = 28 }, // 48
    .{ .note = .D_3 }, .{ .hold = 1 }, // 64
    .{ .note = .E_3 }, .{ .hold = 1 },
    .{ .note = .Fs3 }, .{ .hold = 1 },
    .{ .note = .A_3 }, .{ .hold = 1 },
    .{ .note = .G_3 }, .{ .hold = 1 },
    .{ .note = .A_3 }, .{ .hold = 1 },
    .{ .note = .C_4 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .C_4 }, .{ .hold = 1 }, // 6c
    .{ .note = .A_3 }, .{ .hold = 1 },
    .{ .note = .Fs3 }, .{ .hold = 1 },
    .{ .note = .D_3 }, .{ .hold = 1 },
    .{ .note = .Fs3 }, .{ .hold = 1 },
    .{ .note = .A_3 }, .{ .hold = 1 },
    .{ .note = .C_4 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .A_3 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .G_3 }, .{ .hold = 1 },
    .{ .note = .A_3 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 }, // 78
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .C_4 }, .{ .hold = 1 },
    .{ .note = .C_4 }, .{ .hold = 1 },
    .{ .note = .E_4 }, .{ .hold = 1 },
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .G_4 }, .{ .hold = 1 },
    .{ .note = .Fs4 }, .{ .hold = 1 },
    .{ .note = .G_4 }, .{ .hold = 1 },
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .G_3 }, .{ .hold = 1 }, // 84
    .{ .note = .A_3 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .E_3 }, .{ .hold = 1 },
    .{ .note = .D_4 }, .{ .hold = 1 },
    .{ .note = .C_4 }, .{ .hold = 1 },
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .note = .A_3 }, .{ .hold = 1 },
    .{ .note = .G_3 }, .{ .hold = 1 },
    .{ .note = .D_3 }, .{ .hold = 1 },
    .{ .note = .G_3 }, .{ .hold = 1 },
    .{ .note = .Fs3 }, .{ .hold = 1 },
    .{ .note = .G_3 }, .{ .hold = 1 }, // 90
    .{ .note = .B_3 }, .{ .hold = 1 },
    .{ .goto = 0x9 },
};

/// Track bytecode for channel 2.
const track_data_pulse_2: []const OpCode = &.{
    .{ .volume = 0xa },
    .{ .decay = 0x7 },
    .{ .transpose = 0 },
    .{ .tempo = track_tempo },
    .{ .hold = 2 },
    .{ .note = .D_2 }, .{ .hold = 1 }, // 02
    .{ .note = .G_2 }, .{ .hold = 6 }, // 03
    .{ .note = .G_2 }, .{ .hold = 5 }, // 09
    .{ .note = .G_2 }, .{ .hold = 1 }, // 0e
    .{ .note = .C_2 }, .{ .hold = 6 }, // 0f
    .{ .note = .D_2 }, .{ .hold = 6 }, // 15
    .{ .note = .A_2 }, .{ .hold = 4 }, // 1b
    .{ .note = .D_2 }, .{ .hold = 1 }, // 1f
    .{ .note = .Fs2 }, .{ .hold = 1 }, // 20
    .{ .note = .G_2 }, .{ .hold = 1 }, // 21
    .{ .note = .E_2 }, .{ .hold = 1 }, // 22
    .{ .note = .Fs2 }, .{ .hold = 1 }, // 23
    .{ .note = .D_2 }, .{ .hold = 3 }, // 24
    .{ .note = .G_2 }, .{ .hold = 6 }, // 27
    .{ .note = .G_2 }, .{ .hold = 6 }, // 2d
    .{ .note = .C_2 }, .{ .hold = 3 }, // 33
    .{ .note = .C_2 }, .{ .hold = 3 }, // 36
    .{ .note = .G_2 }, .{ .hold = 3 }, // 39
    .{ .note = .D_2 }, .{ .hold = 3 }, // 3c
    .{ .note = .G_2 }, .{ .hold = 5 }, // 3f
    .{ .volume = 0xb },
    .{ .note = .D_3 }, .{ .hold = 1 }, // 44
    .{ .note = .B_3 }, .{ .hold = 1 }, // 45
    .{ .note = .G_4 }, .{ .hold = 2 }, // 46
    .{ .volume = 0xf },
    .{ .note = .B_4 }, .{ .hold = 6 }, // 48
    .{ .note = .C_5 }, .{ .hold = 3 }, // 4e
    .{ .note = .D_5 }, .{ .hold = 6 }, // 51
    .{ .note = .D_5 }, .{ .hold = 3 }, // 57
    .{ .note = .C_5 }, .{ .hold = 6 }, // 5a
    .{ .note = .B_4 }, .{ .hold = 3 }, // 60
    .{ .note = .A_4 }, .{ .hold = 6 }, // 63
    .{ .volume = 0xa },
    .{ .note = .Fs2 }, .{ .hold = 6 }, // 69
    .{ .note = .D_2 }, .{ .hold = 6 }, // 6f
    .{ .note = .G_2 }, .{ .hold = 4 }, // 75
    .{ .note = .G_2 }, .{ .hold = 2 }, // 79
    .{ .note = .G_2 }, .{ .hold = 6 }, // 7b
    .{ .note = .G_2 }, .{ .hold = 6 }, // 81
    .{ .note = .C_2 }, .{ .hold = 3 }, // 87
    .{ .note = .D_2 }, .{ .hold = 3 }, // 8a
    .{ .note = .G_2 }, .{ .hold = 3 }, // 8d
    .{ .note = .D_3 }, .{ .hold = 2 }, // 90
    .{ .goto = 0x5 },
};

/// Track bytecode for channel 4.
const track_data_noise: []const OpCode = &.{
    .{ .volume = 0x2 },
    .{ .decay = 0x2 },
    .{ .tempo = track_tempo },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 6 }, // 00
    .{ .volume = 0x5 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 6 }, // 0c
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 6 }, // 18
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 1 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 2 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 6 }, // 24
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 6 }, // 30
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 6 }, // 3c
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 1 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 2 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 6 }, // 48
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 5 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 1 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 }, // 60
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 6 }, // 6c
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 6 }, // 78
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 6 }, // 84
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 3 },
    .{ .note = @enumFromInt(0x00) }, .{ .hold = 6 }, // 90
    .{ .goto = 0x6 },
};
// zig fmt: on

/// Enumeration of possible hardware channel outputs for a track.
const ChannelOutput = enum(u2) {
    pulse_1,
    pulse_2,
    wave,
    noise,
};

/// Encapsulates playback state data for a track.
const Track = struct {
    /// Playback bytecode.
    data: []const OpCode,
    /// Current playback position in the bytecode.
    position: u16 = 0,
    /// Playback position of the last OpCode.note.
    last_note_position: u16 = 0,
    /// Rate to use for pulse waves. Set by OpCode.note commands.
    rate: u11 = 0,
    /// Wait this many frames before the next command. Set by `.hold` commands.
    hold_time: u16 = 0,
    /// Transpose the pitch of OpCode.note commands. Set by OpCode.transpose.
    transpose: i8 = 0,
    /// Current playback tempo. Multiply OpCode.hold times by this amount.
    /// Set by `.tempo` commands.
    tempo: u8 = 1,
    /// Current initial volume of notes. Set by `.volume`.
    volume: u4 = 0,
    /// Current duty setting for pulse channels. Set by op_duty.
    duty: gba.sound.PulseControl.Duty = .cycle_1_2,
    /// Identify to which hardware channel this object writes its output.
    output: ChannelOutput,
    /// Current volume envelope decay step for notes. Set by op_decay.
    decay: u3 = 0,

    /// Reset playback state.
    pub fn reset(self: *Track) void {
        self.* = .{
            .data = self.data,
            .output = self.output,
        };
    }

    /// This function is called by the Tracker once per frame.
    pub fn update(self: *Track) void {
        var reset_note: bool = false;
        if (self.hold_time != 0) {
            self.hold_time -= 1;
        }
        while (self.hold_time == 0) : (self.position += 1) {
            if (self.position >= self.data.len) {
                self.position = 0;
            }
            switch (self.data[self.position]) {
                .hold => |hold| {
                    self.hold_time = hold * self.tempo;
                },
                .note => |pitch| {
                    self.rate = pitch.transpose(self.transpose).rate();
                    self.last_note_position = self.position;
                    reset_note = true;
                },
                .volume => |volume| {
                    self.volume = volume;
                },
                .decay => |decay| {
                    self.decay = decay;
                },
                .transpose => |semitones| {
                    self.transpose +%= semitones;
                },
                .tempo => |tempo| {
                    self.tempo = tempo;
                },
                .duty => |duty| {
                    self.duty = duty;
                },
                .goto => |dest| {
                    self.position = dest - 1;
                },
            }
        }
        switch (self.output) {
            .pulse_1 => {
                gba.sound.pulse_1.ctrl = gba.sound.PulseControl{
                    .len = 0x3f,
                    .duty = self.duty,
                    .step = self.decay,
                    .volume = self.volume,
                };
                gba.sound.pulse_1.freq = gba.sound.ChannelFrequency{
                    .rate = self.rate,
                    .reset = reset_note,
                };
            },
            .pulse_2 => {
                gba.sound.pulse_2.ctrl = gba.sound.PulseControl{
                    .len = 0x3f,
                    .duty = self.duty,
                    .step = self.decay,
                    .volume = self.volume,
                };
                gba.sound.pulse_2.freq = gba.sound.ChannelFrequency{
                    .rate = self.rate,
                    .reset = reset_note,
                };
            },
            .wave => {},
            .noise => {
                gba.sound.noise.ctrl = gba.sound.Noise.Control{
                    .len = 0x3f,
                    .step = self.decay,
                    .volume = self.volume,
                };
                gba.sound.noise.freq = gba.sound.Noise.Frequency{
                    .shift = 0x1,
                    .divisor = .div_16,
                    .reset = reset_note,
                };
            },
        }
    }
};

/// Encapsulates playback state for all tracks.
const Tracker = struct {
    pulse_1: Track,
    pulse_2: Track,
    noise: Track,

    /// Reset playback for all tracks.
    pub fn reset(self: *Tracker) void {
        self.pulse_1.reset();
        self.pulse_2.reset();
        self.noise.reset();
    }

    /// Call this function once per frame in the main loop.
    pub fn update(self: *Tracker) void {
        self.pulse_1.update();
        self.pulse_2.update();
        self.noise.update();
    }
};

fn drawBlank(pal_index: u4, target: []volatile gba.bg.TextScreenEntry) void {
    const blank_entry = gba.bg.TextScreenEntry{
        .tile_index = 0x7f,
        .palette_index = pal_index,
    };
    for (target) |*entry| {
        entry.* = blank_entry;
    }
}

fn drawHex(value: u8, pal_index: u4, target: [*]volatile gba.bg.TextScreenEntry) void {
    target[0] = gba.bg.TextScreenEntry{
        .tile_index = hex_digits[value >> 4],
        .palette_index = pal_index,
    };
    target[1] = gba.bg.TextScreenEntry{
        .tile_index = hex_digits[value & 0xf],
        .palette_index = pal_index,
    };
}

fn drawDecimal(value: u8, pal_index: u4, target: [*]volatile gba.bg.TextScreenEntry) void {
    const blank_entry = gba.bg.TextScreenEntry{
        .tile_index = 0x7f,
        .palette_index = pal_index,
    };
    if (value < 10) {
        target[0] = blank_entry;
        target[1] = blank_entry;
        target[2] = gba.bg.TextScreenEntry{
            .tile_index = '0' + value,
            .palette_index = pal_index,
        };
    } else if (value < 100) {
        const div10 = gba.bios.div(value, 10);
        target[0] = blank_entry;
        target[1] = gba.bg.TextScreenEntry{
            .tile_index = @intCast('0' + div10.quotient),
            .palette_index = pal_index,
        };
        target[2] = gba.bg.TextScreenEntry{
            .tile_index = @intCast('0' + div10.remainder),
            .palette_index = pal_index,
        };
    } else {
        const div100 = gba.bios.div(value, 100);
        const div10 = gba.bios.div(div100.remainder, 10);
        target[0] = gba.bg.TextScreenEntry{
            .tile_index = @intCast('0' + div100.quotient),
            .palette_index = pal_index,
        };
        target[1] = gba.bg.TextScreenEntry{
            .tile_index = @intCast('0' + div10.quotient),
            .palette_index = pal_index,
        };
        target[2] = gba.bg.TextScreenEntry{
            .tile_index = @intCast('0' + div10.remainder),
            .palette_index = pal_index,
        };
    }
}

fn drawPitch(pitch: Pitch, pal_index: u4, target: [*]volatile gba.bg.TextScreenEntry) void {
    for (target[0..3], pitch.name()) |*entry, char| {
        entry.* = gba.bg.TextScreenEntry{
            .tile_index = char,
            .palette_index = pal_index,
        };
    }
}

fn drawText(text: []const u8, pal_index: u4, bg_x: u8, bg_y: u8) void {
    const map = gba.bg.screenBlockMap(24);
    for (0..text.len) |text_i| {
        map[bg_x + (@as(u16, bg_y) << 5) + text_i] = gba.bg.TextScreenEntry{
            .tile_index = text[text_i],
            .palette_index = pal_index,
        };
    }
}

fn updateDisplay(track: *const Track, bg_x: u8) void {
    // Format: [2:address hex] [1:opcode icon] [3:operand]
    const map = gba.bg.screenBlockMap(24);
    const offset_y: u16 = 7;
    for (0..16) |row_i| {
        const bg_y = row_i + 2;
        const map_i = bg_x + (bg_y << 5);
        if (track.last_note_position + row_i < offset_y) {
            drawBlank(1, map[map_i .. map_i + 6]);
            continue;
        }
        const track_row = track.last_note_position + row_i - offset_y;
        if (track_row + 1 >= track.data.len) {
            drawBlank(1, map[map_i .. map_i + 6]);
            continue;
        }
        const active = (row_i == offset_y);
        const opcode = track.data[track_row];
        // Address (hex)
        drawHex(@truncate(track_row), 1, map + map_i);
        // Opcode (icon)
        map[map_i + 2] = gba.bg.TextScreenEntry{
            .tile_index = opcode.tileIndex(),
            .palette_index = if (active) 2 else 0,
        };
        // Operand (varies)
        const operand_pal_index: u4 = if (active) 2 else 0;
        switch (opcode) {
            .note => |pitch| {
                drawPitch(pitch, operand_pal_index, map + map_i + 3);
            },
            .goto => |dest| {
                drawBlank(operand_pal_index, map[map_i + 3 .. map_i + 4]);
                drawHex(dest, operand_pal_index, map + map_i + 4);
            },
            else => |op| {
                drawDecimal(op.operandAsByte(), operand_pal_index, map + map_i + 3);
            },
        }
    }
}

pub fn main() void {
    // Initialize sound engine data.
    var tracker = Tracker{
        .pulse_1 = .{
            .data = track_data_pulse_1,
            .output = .pulse_1,
        },
        .pulse_2 = .{
            .data = track_data_pulse_2,
            .output = .pulse_2,
        },
        .noise = .{
            .data = track_data_noise,
            .output = .noise,
        },
    };

    // Initialize sound registers to allow playback.
    gba.sound.enable.* = gba.sound.Status{
        .pulse_1 = .enable,
        .pulse_2 = .enable,
        .noise = .enable,
        .master = .enable,
    };
    gba.sound.dmg.* = gba.sound.Dmg{
        .volume_left = 0x7,
        .volume_right = 0x7,
        .left = gba.sound.ChannelEnable{
            .pulse_1 = .enable,
            .pulse_2 = .enable,
            .noise = .enable,
        },
        .right = gba.sound.ChannelEnable{
            .pulse_1 = .enable,
            .pulse_2 = .enable,
            .noise = .enable,
        },
    };
    gba.sound.bias.* = gba.sound.Bias{
        .cycle = .bits_6,
    };

    // Initialize graphics.
    gba.bg.ctrl[0] = gba.bg.Control{
        .screen_base_block = 24,
        .tile_map_size = .{ .normal = .@"32x32" },
    };
    gba.bg.scroll[0].set(0, 0);
    gba.bg.palette.banks[0][1] = .rgb(31, 31, 31);
    gba.bg.palette.banks[0][2] = .rgb(0, 0, 0);
    gba.bg.palette.banks[1][1] = .rgb(31, 31, 31);
    gba.bg.palette.banks[1][2] = .rgb(19, 19, 19);
    gba.bg.palette.banks[2][1] = .rgb(1, 0, 25);
    gba.bg.palette.banks[2][2] = .rgb(31, 31, 31);
    gba.display.memcpyCharBlock(0, &charset_data);
    gba.display.ctrl.* = gba.display.Control{
        .bg0 = .enable,
    };

    var playing: bool = false;
    var frame: u8 = 0;

    drawText("Pulse1", 2, 4, 0);
    drawText("Pulse2", 2, 12, 0);
    drawText("Noise ", 2, 20, 0);
    drawText("A\x0e    B\x0c    R\x0f", 1, 8, 19);

    // Main loop. Update the Tracker once per frame.
    while (true) : (frame +%= 1) {
        gba.display.naiveVSync();
        _ = gba.input.poll();
        // Toggle paused/playing upon pressing A.
        if (gba.input.isKeyJustPressed(.A)) {
            playing = !playing;
        }
        // Stop playback upon pressing B.
        if (gba.input.isKeyJustPressed(.B)) {
            playing = false;
            tracker.reset();
        }
        // Fast-forward when holding R.
        const fast_forward = gba.input.isKeyPressed(.R);
        // Play music, and flash the A button prompt if paused.
        if (playing) {
            tracker.update();
            if (fast_forward) tracker.update();
            drawText("A\x0d", 1, 8, 19);
        } else {
            drawText("A\x0e", if ((frame & 0x7f) < 0x40) 2 else 0, 8, 19);
        }
        // Draw tracker state.
        updateDisplay(&tracker.pulse_1, 4);
        updateDisplay(&tracker.pulse_2, 12);
        updateDisplay(&tracker.noise, 20);
    }
}
