const std = @import("std");
const gba = @import("gba.zig");
const Enable = gba.utils.Enable;

// References:
// https://problemkaputt.de/gbatek.htm#gbasoundcontroller
// https://gbadev.net/tonc/sndsqr.html
// https://wiki.nycresistor.com/wiki/GB101:Sound
// https://www.gamedev.net/articles/programming/general-and-gameplay-programming/audio-programming-on-the-gameboy-advance-part-1-r1823/
// https://gbdev.gg8.se/wiki/articles/Gameboy_sound_hardware

/// Enumeration of possible square wave duty cycles.
pub const PulseDuty = enum(u2) {
    cycle_1_8 = 0,
    cycle_1_4 = 1,
    cycle_1_2 = 2,
    cycle_3_4 = 3,
};

pub const EnvelopeDirection = enum(u1) {
    /// Volume decreases over time.
    decreases = 0,
    /// Volume increases over time.
    increases = 1,
};

pub const SweepDirection = enum(u1) {
    /// Rate, and therefore also pitch/frequency, increases over time.
    increases = 0,
    /// Rate, and therefore also pitch/frequency, decreases over time.
    decreases = 1,
};

pub const WaveDimension = enum(u1) {
    /// One bank (32 digits)
    single,
    /// Two banks (64 digits)
    double,
};

pub const WaveVolume = enum(u2) {
    /// Volume at 0% (Silent)
    pc_0 = 0,
    /// Volume at 100% (Full)
    pc_100 = 1,
    /// Volume at 50% (Half)
    pc_50 = 2,
    /// Volume at 25% (Quarter)
    pc_25 = 3,
};

pub const NoiseMode = enum(u1) {
    /// Noise LSFR repeats over a longer interval. Noise sounds smoother.
    bits_15 = 0,
    /// Noise LSFR repeats over a shorter interval. Noise sounds harsher.
    bits_7 = 1,
};

pub const NoiseDivisor = enum(u4) {
    div_8 = 0,
    div_16 = 1,
    div_32 = 2,
    div_48 = 3,
    div_64 = 4,
    div_80 = 5,
    div_96 = 6,
    div_112 = 7,
};

pub const PulseChannelSweep = packed struct(u16) {
    /// The higher the shift, the slower the sweep.
    /// At each step, the new rate becomes rate ± rate/2^shift.
    shift: u3 = 0,
    /// Whether the sweep takes the rate up or down.
    dir: SweepDirection = .increases,
    /// Sweep step-time. The time between sweeps is measured
    /// in increments of 128 Hz. Time is step/128 milliseconds.
    /// Range of [7.8, 54.7] milliseconds.
    /// Set to zero to disable sweep.
    step: u3 = 0,
    /// Unused bits.
    _: u9 = 0,
};

pub const PulseChannelControl = packed struct(u16) {
    /// Sound length. This is a write-only field and only works
    /// if the channel is timed.
    /// Length is equal to (64-len)/256 seconds, for a range of
    /// [3.9, 250] milliseconds.
    len: u6 = 0,
    /// Pulse wave duty cycle, as a ratio between on and off
    /// times of the square wave.
    duty: PulseDuty = .cycle_1_8,
    /// Envelope step-time. Time between envelope changes is
    /// step/64 seconds.
    step: u3 = 0,
    /// Whether the envelope increases or decreases with each step.
    dir: EnvelopeDirection = .decreases,
    /// Envelope initial volume.
    /// 0 means silent and 15 means full volume.
    volume: u4 = 0,
};

pub const PulseChannelFrequency = packed struct(u16) {
    /// Initial sound rate. Write-only. Frequency is 2^17/(2048-rate).
    /// See the Pitch enum for rates corresponding to musical notes.
    rate: u11 = 0,
    /// Unused bits.
    _: u3 = 0,
    /// Timed flag. If set, the sound plays for a duration determined
    /// by the channel's ctrl.len field. If clear, it plays forever.
    timed: Enable = .disable,
    /// Sound reset. Resets sound to the initial volume and sweep
    /// settings, when enabled.
    reset: Enable = .disable,
};

pub const WaveChannelSelect = packed struct(u16) {
    /// Unused bits.
    _1: u4 = 0,
    /// Wave RAM dimension.
    dimension: WaveDimension = .single,
    /// Wave RAM bank number.
    bank: u1 = 0,
    /// Whether the channel is stopped or playing.
    playback: Enable = .disable,
    /// Unused bits.
    _2: u8 = 0,
};

pub const WaveChannelControl = packed struct(u16) {
    /// Length is equal to (256-len)/256 seconds.
    len: u8 = 0,
    /// Unused bits.
    _: u5 = 0,
    /// Playback volume.
    volume: WaveVolume = .pc_0,
    /// When enabled, overrides the previous volume setting and
    /// sets volume to 75% instead.
    force_volume_75: Enable = .disable,
};

/// The rate value determines sample rate, measured in sample
/// digits per second.
pub const WaveChannelFrequency = PulseChannelFrequency;

/// Duty is ignored.
pub const NoiseChannelControl = PulseChannelControl;

pub const NoiseChannelFrequency = packed struct(u16) {
    /// Frequency timer period is set by the divisor shifted left
    /// by this many bits.
    shift: u3 = 0,
    /// Determines whether the linear feedback shift register (LSFR)
    /// used to generate noise has an effective width of 15 or 7 bits.
    /// This determines the length of period before the noise waveform
    /// is repeated.
    mode: NoiseMode = .bits_15,
    /// Affects frequency timer period.
    divisor: NoiseDivisor = .div_8,
    /// Unused bits.
    _: u6 = 0,
    /// Timed flag. If set, the sound plays for a duration determined
    /// by the channel's ctrl.len field. If clear, it plays forever.
    timed: Enable = .disable,
    /// Sound reset. Resets sound to the initial volume and sweep
    /// settings.
    reset: Enable = .disable,
};

pub const Dmg = packed struct(u16) {
    volume_left: u3 = 0,
    /// Unused bits.
    _1: u1 = 0,
    volume_right: u3 = 0,
    /// Unused bits.
    _2: u1 = 0,
    left_pulse_1: Enable = .disable,
    left_pulse_2: Enable = .disable,
    left_wave: Enable = .disable,
    left_noise: Enable = .disable,
    right_pulse_1: Enable = .disable,
    right_pulse_2: Enable = .disable,
    right_wave: Enable = .disable,
    right_noise: Enable = .disable,
};

pub const DmgVolumeRatio = enum(u2) {
    /// 25% DMG volume ratio
    pc_25 = 0b00,
    /// 50% DMG volume ratio
    pc_50 = 0b01,
    /// 100% DMG volume ratio
    pc_100 = 0b10,
};

pub const DSoundVolumeRatio = enum(u2) {
    /// 50% DSound A/B volume ratio
    pc_50 = 0,
    /// 100% DSound A/B volume ratio
    pc_100 = 1,
};

pub const DSound = packed struct(u16) {
    /// Relative volume of DMG channels.
    dmg_volume_ratio: DmgVolumeRatio,
    /// Relative volume of DSound A.
    dsound_volume_ratio_a: DSoundVolumeRatio,
    /// Relative volume of DSound B.
    dsound_volume_ratio_b: DSoundVolumeRatio,
    /// Unused bits.
    _: u4 = 0,
    /// Enable DSound A on left speaker.
    left_dsound_a: Enable = .disable,
    /// Enable DSound A on right speaker.
    right_dsound_a: Enable = .disable,
    /// DSound A timer.
    timer_dsound_a: Enable = .disable,
    /// FIFO reset for DSound A. When using DMA for Direct sound,
    /// this will cause DMA to reset the FIFO buffer after it's used.
    reset_dsound_a: Enable = .disable,
    /// Enable DSound B on left speaker.
    left_dsound_b: Enable = .disable,
    /// Enable DSound B on right speaker.
    right_dsound_b: Enable = .disable,
    /// DSound B timer.
    timer_dsound_b: Enable = .disable,
    /// FIFO reset for DSound B. When using DMA for Direct sound,
    /// this will cause DMA to reset the FIFO buffer after it's used.
    reset_dsound_b: Enable = .disable,
};

pub const Stat = packed struct(u16) {
    /// Whether the Pulse 1 channel should be currently playing.
    pulse_1: Enable = .disable,
    /// Whether the Pulse 2 channel should be currently playing.
    pulse_2: Enable = .disable,
    /// Whether the Wave channel should be currently playing.
    wave: Enable = .disable,
    /// Whether the Noise channel should be currently playing.
    noise: Enable = .disable,
    /// Unused bits.
    _1: u3 = 0,
    /// Master sound enable. Must be set if any sound is to be
    /// heard at all.
    master: Enable = .disable,
    /// Unused bits.
    _2: u8 = 0,
};

pub const BiasCycle = enum(u2) {
    /// 32.768 kHz. (Default, best for DMA channels A, B.)
    bits_9 = 0,
    /// 65.536 kHz.
    bits_8 = 1,
    /// 131.072 kHz.
    bits_7 = 2,
    /// 262.144 kHz. (Best for PSG channels 1-4.)
    bits_6 = 3,
};

pub const Bias = packed struct(u16) {
    /// Unused bits.
    _1: u1 = 0,
    /// Bias level, converting signed samples into unsigned.
    level: u9 = 0x100,
    /// Unused bits.
    _2: u4 = 0,
    /// Amplitude resolution/sampling cycle.
    cycle: BiasCycle = .bits_9,
};

/// Control pitch sweep in channel 1 (Pulse 1).
/// Corresponds to tonc REG_SND1SWEEP.
pub const ch1_sweep: *volatile PulseChannelSweep = @ptrFromInt(gba.mem.io + 0x60);

/// Control length, duty, and envelope in channel 1 (Pulse 1).
/// Corresponds to tonc REG_SND1CNT.
pub const ch1_ctrl: *volatile PulseChannelControl = @ptrFromInt(gba.mem.io + 0x62);

/// Control rate (determines pitch/frequency) in channel 1 (Pulse 1).
/// Corresponds to tonc REG_SND1FREQ.
pub const ch1_freq: *volatile PulseChannelFrequency = @ptrFromInt(gba.mem.io + 0x64);

/// Control length, duty, and envelope in channel 2 (Pulse 2).
/// Corresponds to tonc REG_SND2CNT.
pub const ch2_ctrl: *volatile PulseChannelControl = @ptrFromInt(gba.mem.io + 0x68);

/// Control rate (determines pitch/frequency) in channel 2 (Pulse 2).
/// Corresponds to tonc REG_SND2FREQ.
pub const ch2_freq: *volatile PulseChannelFrequency = @ptrFromInt(gba.mem.io + 0x6c);

/// Waveform select for channel 3 (Wave).
/// Corresponds to REG_SND3SEL.
pub const ch3_mode: *volatile WaveChannelSelect = @ptrFromInt(gba.mem.io + 0x70);

/// Corresponds to tonc REG_SND3CNT.
pub const ch3_ctrl: *volatile WaveChannelControl = @ptrFromInt(gba.mem.io + 0x72);

/// Corresponds to tonc REG_SND3FREQ.
pub const ch3_freq: *volatile WaveChannelFrequency = @ptrFromInt(gba.mem.io + 0x74);

/// Corresponds to tonc REG_SND4CNT.
pub const ch4_ctrl: *volatile NoiseChannelControl = @ptrFromInt(gba.mem.io + 0x78);

/// Corresponds to tonc REG_SND4FREQ.
pub const ch4_freq: *volatile NoiseChannelFrequency = @ptrFromInt(gba.mem.io + 0x7c);

/// Corresponds to tonc REG_SNDDMGCNT.
pub const dmg: *volatile Dmg = @ptrFromInt(gba.mem.io + 0x80);

/// Corresponds to tonc REG_SNDDSCNT.
pub const dsound: *volatile DSound = @ptrFromInt(gba.mem.io + 0x82);

/// Corresponds to tonc REG_SNDSTAT.
pub const stat: *volatile Stat = @ptrFromInt(gba.mem.io + 0x84);

/// Corresponds to tonc REG_SNDBIAS.
pub const bias: *volatile Bias = @ptrFromInt(gba.mem.io + 0x88);

/// Corresponds to tonc REG_WAVE_RAM0.
pub const wave_ram_0: *volatile u32 = @ptrFromInt(gba.mem.io + 0x90);

/// Corresponds to tonc REG_WAVE_RAM1.
pub const wave_ram_1: *volatile u32 = @ptrFromInt(gba.mem.io + 0x94);

/// Corresponds to tonc REG_WAVE_RAM2.
pub const wave_ram_2: *volatile u32 = @ptrFromInt(gba.mem.io + 0x98);

/// Corresponds to tonc REG_WAVE_RAM3.
pub const wave_ram_3: *volatile u32 = @ptrFromInt(gba.mem.io + 0x9c);

/// Corresponds to tonc REG_FIFO_A.
pub const fifo_a: *volatile u32 = @ptrFromInt(gba.mem.io + 0xa0);

/// Corresponds to tonc REG_FIFO_B.
pub const fifo_b: *volatile u32 = @ptrFromInt(gba.mem.io + 0xa4);
