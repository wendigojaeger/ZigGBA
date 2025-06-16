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

const pitch_names: [84][]const u8 = .{
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

/// Opcode for music track bytecode, to be followed by an operand:
/// Wait N frames * tempo before the next command.
const op_hold: u8 = 0x00;
/// Opcode for music track bytecode, to be followed by an operand:
/// Begin playing a note with a given pitch.
const op_note: u8 = 0x01;
/// Opcode for music track bytecode, to be followed by an operand:
/// Set the volume of subsequent notes.
const op_volume: u8 = 0x02;
/// Opcode for music track bytecode, to be followed by an operand:
/// Set the volume envelope decay step of subsequent note.
const op_decay: u8 = 0x03;
/// Opcode for music track bytecode, to be followed by an operand:
/// Transpose the pitch of subsequent notes. Adds to pitch.
const op_transpose_up: u8 = 0x04;
/// Opcode for music track bytecode, to be followed by an operand:
/// Transpose the pitch of subsequent notes. Subtracts from pitch.
const op_transpose_down: u8 = 0x05;
/// Opcode for music track bytecode, to be followed by an operand:
/// Set the frame intervals used by op_hold commands.
const op_tempo: u8 = 0x06;
/// Opcode for music track bytecode, to be followed by an operand:
/// Set duty on pulse channels.
const op_duty: u8 = 0x07;
/// Opcode for music track bytecode, to be followed by an operand:
/// Jump to another command in the bytecode.
const op_goto: u8 = 0x08;

const pitch_C_2: u8 = 0x0;
const pitch_Cs2: u8 = 0x1;
const pitch_D_2: u8 = 0x2;
const pitch_Ds2: u8 = 0x3;
const pitch_E_2: u8 = 0x4;
const pitch_F_2: u8 = 0x5;
const pitch_Fs2: u8 = 0x6;
const pitch_G_2: u8 = 0x7;
const pitch_Gs2: u8 = 0x8;
const pitch_A_2: u8 = 0x9;
const pitch_As2: u8 = 0xa;
const pitch_B_2: u8 = 0xb;
const pitch_C_3: u8 = 0xc;
const pitch_Cs3: u8 = 0xd;
const pitch_D_3: u8 = 0xe;
const pitch_Ds3: u8 = 0xf;
const pitch_E_3: u8 = 0x10;
const pitch_F_3: u8 = 0x11;
const pitch_Fs3: u8 = 0x12;
const pitch_G_3: u8 = 0x13;
const pitch_Gs3: u8 = 0x14;
const pitch_A_3: u8 = 0x15;
const pitch_As3: u8 = 0x16;
const pitch_B_3: u8 = 0x17;
const pitch_C_4: u8 = 0x18;
const pitch_Cs4: u8 = 0x19;
const pitch_D_4: u8 = 0x1a;
const pitch_Ds4: u8 = 0x1b;
const pitch_E_4: u8 = 0x1c;
const pitch_F_4: u8 = 0x1d;
const pitch_Fs4: u8 = 0x1e;
const pitch_G_4: u8 = 0x1f;
const pitch_Gs4: u8 = 0x20;
const pitch_A_4: u8 = 0x21;
const pitch_As4: u8 = 0x22;
const pitch_B_4: u8 = 0x23;
const pitch_C_5: u8 = 0x24;
const pitch_Cs5: u8 = 0x25;
const pitch_D_5: u8 = 0x26;
const pitch_Ds5: u8 = 0x27;
const pitch_E_5: u8 = 0x28;
const pitch_F_5: u8 = 0x29;
const pitch_Fs5: u8 = 0x2a;
const pitch_G_5: u8 = 0x2b;
const pitch_Gs5: u8 = 0x2c;
const pitch_A_5: u8 = 0x2d;
const pitch_As5: u8 = 0x2e;
const pitch_B_5: u8 = 0x2f;
const pitch_C_6: u8 = 0x30;
const pitch_Cs6: u8 = 0x31;
const pitch_D_6: u8 = 0x32;
const pitch_Ds6: u8 = 0x33;
const pitch_E_6: u8 = 0x34;
const pitch_F_6: u8 = 0x35;
const pitch_Fs6: u8 = 0x36;
const pitch_G_6: u8 = 0x37;
const pitch_Gs6: u8 = 0x38;
const pitch_A_6: u8 = 0x39;
const pitch_As6: u8 = 0x3a;
const pitch_B_6: u8 = 0x3b;
const pitch_C_7: u8 = 0x3c;
const pitch_Cs7: u8 = 0x3d;
const pitch_D_7: u8 = 0x3e;
const pitch_Ds7: u8 = 0x3f;
const pitch_E_7: u8 = 0x40;
const pitch_F_7: u8 = 0x41;
const pitch_Fs7: u8 = 0x42;
const pitch_G_7: u8 = 0x43;
const pitch_Gs7: u8 = 0x44;
const pitch_A_7: u8 = 0x45;
const pitch_As7: u8 = 0x46;
const pitch_B_7: u8 = 0x47;
const pitch_C_8: u8 = 0x48;
const pitch_Cs8: u8 = 0x49;
const pitch_D_8: u8 = 0x4a;
const pitch_Ds8: u8 = 0x4b;
const pitch_E_8: u8 = 0x4c;
const pitch_F_8: u8 = 0x4d;
const pitch_Fs8: u8 = 0x4e;
const pitch_G_8: u8 = 0x4f;
const pitch_Gs8: u8 = 0x50;
const pitch_A_8: u8 = 0x51;
const pitch_As8: u8 = 0x52;
const pitch_B_8: u8 = 0x53;

/// Table of pulse channel rates corresponding to musical notes.
/// Rates are computed as `round(2048 - ((2**17) / hz))`.
const pitch_rate: [0x54]u16 = .{
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

/// Constant used as the tempo value for each track.
const track_tempo: u8 = 0x18;

/// Track bytecode for channel 1.
const track_data_pulse_1 = .{
    op_volume, 0xf,
    op_decay, 0x4,
    op_transpose_up, 0,
    op_tempo, track_tempo,
    op_duty, 1,
    op_note, pitch_B_3, op_hold, 1, // 00
    op_note, pitch_G_3, op_hold, 1,
    op_note, pitch_A_3, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_C_4, op_hold, 1,
    op_note, pitch_C_4, op_hold, 1,
    op_note, pitch_E_4, op_hold, 1,
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_G_4, op_hold, 1,
    op_note, pitch_Fs4, op_hold, 1,
    op_note, pitch_G_4, op_hold, 1, // 0c
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_G_3, op_hold, 1,
    op_note, pitch_A_3, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_C_4, op_hold, 1,
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_E_4, op_hold, 1,
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_C_4, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_A_3, op_hold, 1, // 18
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_G_3, op_hold, 1,
    op_note, pitch_Fs3, op_hold, 1,
    op_note, pitch_G_3, op_hold, 1,
    op_note, pitch_A_3, op_hold, 1,
    op_note, pitch_D_3, op_hold, 1,
    op_note, pitch_Fs3, op_hold, 1,
    op_note, pitch_A_3, op_hold, 1,
    op_note, pitch_C_4, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_A_3, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1, // 24
    op_note, pitch_G_3, op_hold, 1,
    op_note, pitch_A_3, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_C_4, op_hold, 1,
    op_note, pitch_C_4, op_hold, 1,
    op_note, pitch_E_4, op_hold, 1,
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_G_4, op_hold, 1,
    op_note, pitch_Fs4, op_hold, 1,
    op_note, pitch_G_4, op_hold, 1, // 30
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_G_3, op_hold, 1,
    op_note, pitch_A_3, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_E_3, op_hold, 1,
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_C_4, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_A_3, op_hold, 1,
    op_note, pitch_G_3, op_hold, 1,
    op_note, pitch_D_3, op_hold, 1, // 3c
    op_note, pitch_G_3, op_hold, 1,
    op_note, pitch_Fs3, op_hold, 1,
    op_note, pitch_G_3, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_G_4, op_hold, 1,
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_G_3, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_G_4, op_hold, 28, // 48
    op_note, pitch_D_3, op_hold, 1, // 64
    op_note, pitch_E_3, op_hold, 1,
    op_note, pitch_Fs3, op_hold, 1,
    op_note, pitch_A_3, op_hold, 1,
    op_note, pitch_G_3, op_hold, 1,
    op_note, pitch_A_3, op_hold, 1,
    op_note, pitch_C_4, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_C_4, op_hold, 1, // 6c
    op_note, pitch_A_3, op_hold, 1,
    op_note, pitch_Fs3, op_hold, 1,
    op_note, pitch_D_3, op_hold, 1,
    op_note, pitch_Fs3, op_hold, 1,
    op_note, pitch_A_3, op_hold, 1,
    op_note, pitch_C_4, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_A_3, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_G_3, op_hold, 1,
    op_note, pitch_A_3, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1, // 78
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_C_4, op_hold, 1,
    op_note, pitch_C_4, op_hold, 1,
    op_note, pitch_E_4, op_hold, 1,
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_G_4, op_hold, 1,
    op_note, pitch_Fs4, op_hold, 1,
    op_note, pitch_G_4, op_hold, 1,
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_G_3, op_hold, 1, // 84
    op_note, pitch_A_3, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_E_3, op_hold, 1,
    op_note, pitch_D_4, op_hold, 1,
    op_note, pitch_C_4, op_hold, 1,
    op_note, pitch_B_3, op_hold, 1,
    op_note, pitch_A_3, op_hold, 1,
    op_note, pitch_G_3, op_hold, 1,
    op_note, pitch_D_3, op_hold, 1,
    op_note, pitch_G_3, op_hold, 1,
    op_note, pitch_Fs3, op_hold, 1,
    op_note, pitch_G_3, op_hold, 1, // 90
    op_note, pitch_B_3, op_hold, 1,
    op_goto, 0x9,
};

/// Track bytecode for channel 2.
const track_data_pulse_2 = .{
    op_volume, 0xa,
    op_decay, 0x7,
    op_transpose_down, 0,
    op_tempo, track_tempo,
    op_hold, 2,
    op_note, pitch_D_2, op_hold, 1, // 02
    op_note, pitch_G_2, op_hold, 6, // 03
    op_note, pitch_G_2, op_hold, 5, // 09
    op_note, pitch_G_2, op_hold, 1, // 0e
    op_note, pitch_C_2, op_hold, 6, // 0f
    op_note, pitch_D_2, op_hold, 6, // 15
    op_note, pitch_A_2, op_hold, 4, // 1b
    op_note, pitch_D_2, op_hold, 1, // 1f
    op_note, pitch_Fs2, op_hold, 1, // 20
    op_note, pitch_G_2, op_hold, 1, // 21
    op_note, pitch_E_2, op_hold, 1, // 22
    op_note, pitch_Fs2, op_hold, 1, // 23
    op_note, pitch_D_2, op_hold, 3, // 24
    op_note, pitch_G_2, op_hold, 6, // 27
    op_note, pitch_G_2, op_hold, 6, // 2d
    op_note, pitch_C_2, op_hold, 3, // 33
    op_note, pitch_C_2, op_hold, 3, // 36
    op_note, pitch_G_2, op_hold, 3, // 39
    op_note, pitch_D_2, op_hold, 3, // 3c
    op_note, pitch_G_2, op_hold, 5, // 3f
    op_volume, 0xb,
    op_note, pitch_D_3, op_hold, 1, // 44
    op_note, pitch_B_3, op_hold, 1, // 45
    op_note, pitch_G_4, op_hold, 2, // 46
    op_volume, 0xf,
    op_note, pitch_B_4, op_hold, 6, // 48
    op_note, pitch_C_5, op_hold, 3, // 4e
    op_note, pitch_D_5, op_hold, 6, // 51
    op_note, pitch_D_5, op_hold, 3, // 57
    op_note, pitch_C_5, op_hold, 6, // 5a
    op_note, pitch_B_4, op_hold, 3, // 60
    op_note, pitch_A_4, op_hold, 6, // 63
    op_volume, 0xa,
    op_note, pitch_Fs2, op_hold, 6, // 69
    op_note, pitch_D_2, op_hold, 6, // 6f
    op_note, pitch_G_2, op_hold, 4, // 75
    op_note, pitch_G_2, op_hold, 2, // 79
    op_note, pitch_G_2, op_hold, 6, // 7b
    op_note, pitch_G_2, op_hold, 6, // 81
    op_note, pitch_C_2, op_hold, 3, // 87
    op_note, pitch_D_2, op_hold, 3, // 8a
    op_note, pitch_G_2, op_hold, 3, // 8d
    op_note, pitch_D_3, op_hold, 2, // 90
    op_goto, 0x5,
};

/// Track bytecode for channel 3.
const track_data_noise = .{
    op_volume, 0x2,
    op_decay, 0x2,
    op_tempo, track_tempo,
    op_note, 0x00, op_hold, 6, // 00
    op_volume, 0x5,
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 6, // 0c
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 6, // 18
    op_note, 0x00, op_hold, 1,
    op_note, 0x00, op_hold, 2,
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 6, // 24
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 6, // 30
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 6, // 3c
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 1,
    op_note, 0x00, op_hold, 2,
    op_note, 0x00, op_hold, 6, // 48
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 5,
    op_note, 0x00, op_hold, 1,
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 3, // 60
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 6, // 6c
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 6, // 78
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 6, // 84
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 3,
    op_note, 0x00, op_hold, 6, // 90
    op_goto, 0x6,
};

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
    data: []const u8,
    /// Current playback position in the bytecode.
    position: u16 = 0,
    /// Playback position of the last op_note.
    last_note_position: u16 = 0,
    /// Rate to use for pulse waves. Set by op_note commands.
    rate: u16 = 0,
    /// Wait this many frames before the next command. Set by op_hold.
    hold_time: u16 = 0,
    /// Transpose the pitch of op_note commands. Set by op_transpose_up.
    transpose_up: u8 = 0,
    /// Transpose the pitch of op_note commands. Set by op_transpose_down.
    transpose_down: u8 = 0,
    /// Current playback tempo. Multiply op_hold times by this amount.
    /// Set by op_tempo commands.
    tempo: u8 = 1,
    /// Current initial volume of notes. Set by op_volume.
    volume: u4 = 0,
    /// Current duty setting for pulse channels. Set by op_duty.
    duty: gba.sound.PulseDuty = .cycle_1_2,
    /// Identify to which hardware channel this object writes its output.
    output: ChannelOutput,
    /// Current volume envelope decay step for notes. Set by op_decay.
    decay: u3 = 0,
    
    /// Reset playback state.
    pub fn reset(self: *Track) void {
        self.position = 0;
        self.last_note_position = 0;
        self.rate = 0;
        self.hold_time = 0;
        self.transpose_up = 0;
        self.transpose_down = 0;
        self.tempo = 0;
        self.volume = 0;
        self.duty = .cycle_1_2;
        self.decay = 0;
    }
    
    /// This function is called by the Tracker once per frame.
    pub fn update(self: *Track) void {
        var reset_note: Enable = .disable;
        if(self.hold_time != 0) {
            self.hold_time -= 1;
        }
        while(self.hold_time == 0) {
            const pos = self.position;
            const opcode = self.data[pos];
            const operand = self.data[pos + 1];
            self.position += 2;
            if(self.position >= self.data.len) {
                self.position = 0;
            }
            switch(opcode) {
                op_hold => {
                    self.hold_time = operand;
                    self.hold_time *= self.tempo;
                },
                op_note => {
                    const pitch = (
                        operand +
                        self.transpose_up -
                        self.transpose_down
                    );
                    self.rate = pitch_rate[pitch];
                    self.last_note_position = pos;
                    reset_note = .enable;
                },
                op_volume => {
                    self.volume = @intCast(operand);
                },
                op_decay => {
                    self.decay = @intCast(operand);
                },
                op_transpose_up => {
                    self.transpose_up = operand;
                },
                op_transpose_down => {
                    self.transpose_down = operand;
                },
                op_tempo => {
                    self.tempo = operand;
                },
                op_duty => {
                    self.duty = @enumFromInt(operand);
                },
                op_goto => {
                    self.position = operand;
                    self.position <<= 1;
                },
                else => {},
            }
        }
        switch(self.output) {
            .pulse_1 => {
                gba.sound.ch1_ctrl.* = gba.sound.PulseChannelControl {
                    .len = 0x3f,
                    .duty = self.duty,
                    .step = self.decay,
                    .volume = self.volume,
                };
                gba.sound.ch1_freq.* = gba.sound.PulseChannelFrequency {
                    .rate = @intCast(self.rate),
                    .reset = reset_note,
                };
            },
            .pulse_2 => {
                gba.sound.ch2_ctrl.* = gba.sound.PulseChannelControl {
                    .len = 0x3f,
                    .duty = self.duty,
                    .step = self.decay,
                    .volume = self.volume,
                };
                gba.sound.ch2_freq.* = gba.sound.PulseChannelFrequency {
                    .rate = @intCast(self.rate),
                    .reset = reset_note,
                };
            },
            .wave => {},
            .noise => {
                gba.sound.ch4_ctrl.* = gba.sound.NoiseChannelControl {
                    .len = 0x3f,
                    .step = self.decay,
                    .volume = self.volume,
                };
                gba.sound.ch4_freq.* = gba.sound.NoiseChannelFrequency {
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

fn drawBlank(len: u8, pal_index: u4, target: [*]volatile gba.bg.TextScreenEntry) void {
    const blank_entry = gba.bg.TextScreenEntry {
        .tile_index = 0x7f,
        .palette_index = pal_index,
    };
    for(0..len) |i| {
        target[i] = blank_entry;
    }
}

fn drawHex(value: u8, pal_index: u4, target: [*]volatile gba.bg.TextScreenEntry) void {
    target[0] = gba.bg.TextScreenEntry {
        .tile_index = hex_digits[value >> 4],
        .palette_index = pal_index,
    };
    target[1] = gba.bg.TextScreenEntry {
        .tile_index = hex_digits[value & 0xf],
        .palette_index = pal_index,
    };
}

fn drawDecimal(value: u8, pal_index: u4, target: [*]volatile gba.bg.TextScreenEntry) void {
    const blank_entry = gba.bg.TextScreenEntry {
        .tile_index = 0x7f,
        .palette_index = pal_index,
    };
    if(value < 10) {
        target[0] = blank_entry;
        target[1] = blank_entry;
        target[2] = gba.bg.TextScreenEntry {
            .tile_index = '0' + value,
            .palette_index = pal_index,
        };
    }
    else if(value < 100) {
        const div10 = gba.bios.div(value, 10);
        target[0] = blank_entry;
        target[1] = gba.bg.TextScreenEntry {
            .tile_index = @intCast('0' + div10.division),
            .palette_index = pal_index,
        };
        target[2] = gba.bg.TextScreenEntry {
            .tile_index = @intCast('0' + div10.remainder),
            .palette_index = pal_index,
        };
    }
    else {
        const div100 = gba.bios.div(value, 100);
        const div10 = gba.bios.div(div100.remainder, 10);
        target[0] = gba.bg.TextScreenEntry {
            .tile_index = @intCast('0' + div100.division),
            .palette_index = pal_index,
        };
        target[1] = gba.bg.TextScreenEntry {
            .tile_index = @intCast('0' + div10.division),
            .palette_index = pal_index,
        };
        target[2] = gba.bg.TextScreenEntry {
            .tile_index = @intCast('0' + div10.remainder),
            .palette_index = pal_index,
        };
    }
}

fn drawPitch(pitch: u8, pal_index: u4, target: [*]volatile gba.bg.TextScreenEntry) void {
    if(pitch > pitch_names.len) {
        target[0] = gba.bg.TextScreenEntry {
            .tile_index = 'x',
            .palette_index = pal_index,
        };
        drawHex(pitch, pal_index, target + 1);
    }
    else {
        for(0..3) |i| {
            target[i] = gba.bg.TextScreenEntry {
                .tile_index = pitch_names[pitch][i],
                .palette_index = pal_index,
            };
        }
    }
}

fn drawText(text: []const u8, pal_index: u4, bg_x: u8, bg_y: u8) void {
    const map = gba.bg.screenBlockMap(24);
    for(0..text.len) |text_i| {
        map[bg_x + (@as(u16, bg_y) << 5) + text_i] = gba.bg.TextScreenEntry {
            .tile_index = text[text_i],
            .palette_index = pal_index,
        };
    }
}

fn updateDisplay(bg_x: u8, track: *Track) void {
    // Format: [2:address hex] [1:opcode icon] [3:operand]
    const map = gba.bg.screenBlockMap(24);
    const offset_y: u16 = 7;
    for(0..16) |row_i| {
        const bg_y = row_i + 2;
        const map_i = bg_x + (bg_y << 5);
        const track_pos_row = track.last_note_position >> 1;
        if(track_pos_row + row_i < offset_y) {
            drawBlank(6, 1, map + map_i);
            continue;
        }
        const track_row = track_pos_row + row_i - offset_y;
        const track_i = track_row << 1;
        if(track_i + 1 >= track.data.len) {
            drawBlank(6, 1, map + map_i);
            continue;
        }
        const active = (row_i == offset_y);
        const opcode = track.data[track_i];
        const operand = track.data[track_i + 1];
        // Address (hex)
        drawHex(@truncate(track_row), 1, map + map_i);
        // Opcode (icon)
        map[map_i + 2] = gba.bg.TextScreenEntry {
            .tile_index = 0x10 + opcode,
            .palette_index = if(active) 2 else 0,
        };
        // Operand (varies)
        const operand_pal_index: u4 = if(active) 2 else 0;
        switch(opcode) {
            op_note => {
                drawPitch(operand, operand_pal_index, map + map_i + 3);
            },
            op_goto => {
                drawBlank(1, operand_pal_index, map + map_i + 3);
                drawHex(operand, operand_pal_index, map + map_i + 4);
            },
            else => {
                drawDecimal(operand, operand_pal_index, map + map_i + 3);
            },
        }
    }
}

pub fn main() void {
    // Initialize sound engine data.
    var tracker = Tracker {
        .pulse_1 = .{
            .data = &track_data_pulse_1,
            .output = .pulse_1,
        },
        .pulse_2 = .{
            .data = &track_data_pulse_2,
            .output = .pulse_2,
        },
        .noise = .{
            .data = &track_data_noise,
            .output = .noise,
        },
    };
    
    // Initialize sound registers to allow playback.
    gba.sound.stat.* = gba.sound.Stat {
        .pulse_1 = .enable,
        .pulse_2 = .enable,
        .noise = .enable,
        .master = .enable,
    };
    gba.sound.dmg.* = gba.sound.Dmg {
        .volume_left = 0x7,
        .volume_right = 0x7,
        .left_pulse_1 = .enable,
        .left_pulse_2 = .enable,
        .left_noise = .enable,
        .right_pulse_1 = .enable,
        .right_pulse_2 = .enable,
        .right_noise = .enable,
    };
    gba.sound.bias.* = gba.sound.Bias {
        .cycle = .bits_6,
    };
    
    // Initialize graphics.
    gba.bg.ctrl[0] = gba.bg.Control {
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
    gba.display.ctrl.* = gba.display.Control {
        .bg0 = .enable,
    };
    
    var playing: bool = false;
    var frame: u8 = 0;
    
    drawText("Pulse1", 2, 4, 0);
    drawText("Pulse2", 2, 12, 0);
    drawText("Noise ", 2, 20, 0);
    drawText("A\x0e    B\x0c    R\x0f", 1, 8, 19);
    
    // Main loop. Update the Tracker once per frame.
    while (true) {
        gba.display.naiveVSync();
        _ = gba.input.poll();
        // Toggle paused/playing upon pressing A.
        if(gba.input.isKeyJustPressed(.A)) {
            playing = !playing;
        }
        // Stop playback upon pressing B.
        if(gba.input.isKeyJustPressed(.B)) {
            playing = false;
            tracker.reset();
        }
        // Fast-forward when holding R.
        const fast_forward = gba.input.isKeyPressed(.R);
        // Play music, and flash the A button prompt if paused.
        if(playing) {
            tracker.update();
            if(fast_forward) tracker.update();
            drawText("A\x0d", 1, 8, 19);
        }
        else {
            drawText("A\x0e", if((frame & 0x7f) < 0x40) 2 else 0, 8, 19);
        }
        // Draw tracker state.
        updateDisplay(4, &tracker.pulse_1);
        updateDisplay(12, &tracker.pulse_2);
        updateDisplay(20, &tracker.noise);
        frame += 1;
    }
}
