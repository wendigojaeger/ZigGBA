const std = @import("std");
const gba = @import("gba.zig");
const Enable = gba.utils.Enable;

// References:
// https://problemkaputt.de/gbatek.htm#gbasoundcontroller
// https://gbadev.net/tonc/sndsqr.html
// https://wiki.nycresistor.com/wiki/GB101:Sound
// https://www.gamedev.net/articles/programming/general-and-gameplay-programming/audio-programming-on-the-gameboy-advance-part-1-r1823/
// https://gbdev.gg8.se/wiki/articles/Gameboy_sound_hardware

pub const EnvelopeDirection = enum(u1) {
    decrease = 0,
    increase = 1,
};

pub const Duration = enum(u1) {
    forever,
    timed,
};

/// Control register for pulse channels.
pub const PulseControl = packed struct(u16) {
    /// Enumeration of possible square wave duty cycles.
    pub const Duty = enum(u2) {
        cycle_1_8 = 0,
        cycle_1_4 = 1,
        cycle_1_2 = 2,
        cycle_3_4 = 3,
    };
    /// Sound length. This is a write-only field and only works
    /// if the channel is timed.
    /// Length is equal to (64-len)/256 seconds, for a range of
    /// [3.9, 250] milliseconds.
    len: u6 = 0,
    /// Pulse wave duty cycle, as a ratio between on and off
    /// times of the square wave.
    duty: Duty = .cycle_1_8,
    /// Envelope step-time. Time between envelope changes is
    /// step/64 seconds.
    step: u3 = 0,
    /// Whether the envelope increases or decreases with each step.
    dir: EnvelopeDirection = .decrease,
    /// Envelope initial volume.
    /// 0 means silent and 15 means full volume.
    volume: u4 = 0,
};

/// Control for the frequency registers of the pulse and wave channels.
pub const ChannelFrequency = packed struct(u16) {
    /// Initial sound rate. Write-only. Frequency is 2^17/(2048-rate).
    /// See the Pitch enum for rates corresponding to musical notes.
    rate: u11 = 0,
    /// Unused bits.
    _: u3 = 0,
    /// Timed flag. If set, the sound plays for a duration determined
    /// by the channel's ctrl.len field. If clear, it plays forever.
    duration: Duration = .forever,
    /// Sound reset. Resets sound to the initial volume and sweep
    /// settings, when true.
    reset: bool = false,
};

pub const Pulse1 = packed struct(u48) {
    pub const Sweep = packed struct(u16) {
        pub const Direction = enum(u1) {
                /// Rate, and therefore also pitch/frequency, increases over time.
        increases = 0,
        /// Rate, and therefore also pitch/frequency, decreases over time.
        decreases = 1,
        };
        /// The higher the shift, the slower the sweep.
        /// At each step, the new rate becomes rate ± rate/2^shift.
        shift: u3 = 0,
        /// Whether the rate, and therefore also pitch/frequency, increases or decreases over time.
        dir: Sweep.Direction = .increase,
        /// Sweep step-time. The time between sweeps is measured
        /// in increments of 128 Hz. Time is step/128 milliseconds.
        /// Range of [7.8, 54.7] milliseconds.
        /// Set to zero to disable sweep.
        step: u3 = 0,
        /// Unused bits.
        _: u9 = 0,
    };

    pub const Control = PulseControl;
    pub const Frequency = ChannelFrequency;

    /// Control pitch sweep in channel 1 (Pulse 1).
    ///
    /// Corresponds to tonc REG_SND1SWEEP.
    sweep: Pulse1.Sweep = .{},
    /// Control length, duty, and envelope
    ///
    /// Corresponds to tonc REG_SND1CNT
    ctrl: Control = .{},
    /// Control rate (determines pitch/frequency)
    ///
    /// Corresponds to tonc REG_SND1FREQ
    freq: Frequency = .{},
};

pub const Pulse2 = packed struct(u48) {
    /// Control length, duty, and envelope
    ///
    /// Corresponds to tonc REG_SND2CNT
    ctrl: PulseControl = .{},
    /// Unused register.
    _: u16 = 0,
    /// Control rate (determines pitch/frequency)
    ///
    /// Corresponds to tonc REG_SND2FREQ
    freq: ChannelFrequency = .{},
};

pub const Wave = packed struct(u48) {
    pub const Volume = enum(u2) {
        /// Volume at 0%
        silent = 0,
        /// Volume at 100%
        full = 1,
        /// Volume at 50%
        half = 2,
        /// Volume at 25%
        quarter = 3,
    };

    pub const Control = packed struct(u16) {
        /// Length is equal to (256-len)/256 seconds.
        len: u8 = 0,
        /// Unused bits.
        _: u5 = 0,
        /// Playback volume.
        volume: Wave.Volume = .silent,
        /// When enabled, overrides the previous volume setting and
        /// sets volume to 75% instead.
        force_volume_75: Enable = .disable,
    };

    pub const Dimension = enum(u1) {
        /// Use one 32-sample bank for the wave channel.
        single = 0,
        /// Use both banks for the wave channel, for a total of 64 samples.
        /// Note that while both banks are in use in this way, it is unsafe
        /// to write to the REG_WAVE_RAMx registers at all during playback.
        double = 1,
    };

    pub const Select = packed struct(u16) {
        /// Unused bits.
        _1: u5 = 0,
        /// Wave RAM dimension. Determines whether to play a single 32-sample
        /// waveform from the selected bank, or whether to combine both banks
        /// into a double-long 64-sample waveform.
        dimension: Dimension = .single,
        /// Wave RAM bank number selected for playback.
        /// Whichever bank is *not* selected here can be written
        /// to via the REG_WAVE_RAMx registers.
        bank: u1 = 0,
        /// Whether the channel is stopped or playing.
        playback: Enable = .disable,
        /// Unused bits.
        _2: u8 = 0,
    };

    /// Corresponds to REG_SND3SEL
    select: Wave.Select = .{},
    /// Corresponds to REG_SND3CNT
    ctrl: Wave.Control = .{},
    /// Corresponds to REG_SND3FREQ
    freq: ChannelFrequency = .{},
};

pub const Noise = packed struct(u48) {
    pub const Control = packed struct(u16) {
        /// Sound length. This is a write-only field and only works
        /// if the channel is timed.
        /// Length is equal to (64-len)/256 seconds, for a range of
        /// [3.9, 250] milliseconds.
        len: u6 = 0,
        /// Unused for the noise channel.
        _: u2 = 0,
        /// Envelope step-time. Time between envelope changes is
        /// step/64 seconds.
        step: u3 = 0,
        /// Whether the envelope increases or decreases with each step.
        dir: EnvelopeDirection = .decrease,
        /// Envelope initial volume.
        /// 0 means silent and 15 means full volume.
        volume: u4 = 0,
    };
    /// Actual sample rate of the LFSR random bits is
    /// 262114 / (divisor << shift).
    pub const Frequency = packed struct(u16) {
        pub const Divisor = enum(u3) {
            div_8 = 0,
            div_16 = 1,
            div_32 = 2,
            div_48 = 3,
            div_64 = 4,
            div_80 = 5,
            div_96 = 6,
            div_112 = 7,
        };

        ///
        pub const Mode = enum(u1) {
            /// Noise LSFR repeats over a longer interval. Noise sounds smoother.
            bits_15 = 0,
            /// Noise LSFR repeats over a shorter interval. Noise sounds harsher.
            bits_7 = 1,
        };
        /// Dividing ratio of frequencies.
        /// Affects frequency timer period.
        divisor: Divisor = .div_8,

        /// Determines whether the linear feedback shift register (LSFR)
        /// used to generate noise has an effective width of 15 or 7 bits.
        /// This determines the length of period before the noise waveform
        /// is repeated.
        mode: Mode = .bits_15,
        /// Frequency timer period is set by the divisor shifted left
        /// by this many bits.
        shift: u4 = 0,
        /// Unused bits.
        _: u6 = 0,
        /// Duration flag. If set, the sound plays for a duration determined
        /// by the channel's ctrl.len field. If clear, it plays forever.
        duration: Duration = .forever,
        /// Sound reset. Resets sound to the initial volume and sweep
        /// settings.
        reset: bool = false,
    };

    ctrl: Noise.Control = .{},
    _: u16 = 0,
    freq: Noise.Frequency = .{},
};

pub const ChannelEnable = packed struct(u4) {
    /// Whether the Pulse 1 channel should be currently playing.
    pulse_1: Enable = .disable,
    /// Whether the Pulse 2 channel should be currently playing.
    pulse_2: Enable = .disable,
    /// Whether the Wave channel should be currently playing.
    wave: Enable = .disable,
    /// Whether the Noise channel should be currently playing.
    noise: Enable = .disable,
};

/// Represents the contents of the REG_SNDDMGCNT sound control register.
pub const Dmg = packed struct(u16) {
    /// Master volume for left speaker.
    volume_left: u3 = 0,
    /// Unused bits.
    _1: u1 = 0,
    /// Master volume for right speaker.
    volume_right: u3 = 0,
    /// Unused bits.
    _2: u1 = 0,
    /// Enable channels for the left speaker.
    left: ChannelEnable = .{},
    /// Enable channels for the right speaker.
    right: ChannelEnable = .{},
};

pub const DmgVolumeRatio = enum(u2) {
    /// 25% DMG volume ratio
    quarter = 0b00,
    /// 50% DMG volume ratio
    half = 0b01,
    /// 100% DMG volume ratio
    full = 0b10,
};

pub const DirectSound = packed struct(u16) {
    pub const Control = packed struct(u4) {
        /// Enable on left speaker.
        left: Enable = .disable,
        /// Enable on right speaker.
        right: Enable = .disable,
        /// Hardware timer select.
        timer: u1 = 0,
        /// FIFO reset. When using DMA for Direct sound,
        /// this will cause DMA to reset the FIFO buffer after it's used.
        reset_fifo: bool = false,
    };

    pub const VolumeRatio = enum(u2) {
        /// 50% DSound A/B volume ratio
        half = 0,
        /// 100% DSound A/B volume ratio
        full = 1,
    };

    /// Relative volume of DMG channels.
    dmg_volume_ratio: DmgVolumeRatio,
    /// Relative volume of DSound A.
    volume_a: VolumeRatio,
    /// Relative volume of DSound B.
    volume_b: VolumeRatio,
    /// Unused bits.
    _: u4 = 0,
    dsound_a: Control = .{},
    dsound_b: Control = .{},
};

pub const Status = packed struct(u16) {
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

pub const Bias = packed struct(u16) {
    pub const Cycle = enum(u2) {
        /// 32.768 kHz. (Default, best for DMA channels A, B.)
        bits_9 = 0,
        /// 65.536 kHz.
        bits_8 = 1,
        /// 131.072 kHz.
        bits_7 = 2,
        /// 262.144 kHz. (Best for PSG channels 1-4.)
        bits_6 = 3,
    };

    /// Unused bits.
    _1: u1 = 0,
    /// Bias level, converting signed samples into unsigned.
    level: u9 = 0x100,
    /// Unused bits.
    _2: u4 = 0,
    /// Amplitude resolution/sampling cycle.
    cycle: Cycle = .bits_9,
};

/// Access to registers for controlling Pulse channel 1
pub const pulse_1: *volatile Pulse1 = @ptrFromInt(gba.mem.io + 0x60);

/// Access to registers for controlling Pulse channel 2
pub const pulse_2: *volatile Pulse2 = @ptrFromInt(gba.mem.io + 0x68);

/// Access to registers for controlling the Wave channel
pub const wave: *volatile Wave = @ptrFromInt(gba.mem.io + 0x70);

/// Access to registers for controlling the Noise channel
pub const noise: *volatile Noise = @ptrFromInt(gba.mem.io + 0x78);

/// Corresponds to tonc REG_SNDDMGCNT.
pub const dmg: *volatile Dmg = @ptrFromInt(gba.mem.io + 0x80);

/// Corresponds to tonc REG_SNDDSCNT.
pub const direct_sound: *volatile DirectSound = @ptrFromInt(gba.mem.io + 0x82);

/// Corresponds to tonc REG_SNDSTAT.
pub const enable: *volatile Status = @ptrFromInt(gba.mem.io + 0x84);

/// Corresponds to tonc REG_SNDBIAS.
pub const bias: *volatile Bias = @ptrFromInt(gba.mem.io + 0x88);

/// Corresponds to tonc REG_WAVE_RAMx.
pub const wave_ram: *volatile [4]u32 = @ptrFromInt(gba.mem.io + 0x90);

/// Corresponds to tonc REG_FIFO_A.
pub const fifo_a: *volatile [4]u8 = @ptrFromInt(gba.mem.io + 0xa0);

/// Corresponds to tonc REG_FIFO_B.
pub const fifo_b: *volatile [4]u8 = @ptrFromInt(gba.mem.io + 0xa4);
