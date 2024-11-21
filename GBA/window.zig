//! Utilities for windowing

const gba = @import("gba.zig");
const window = @This();
const Enable = gba.Enable;

pub const Bounds = extern struct {
    pub const Horizontal = packed struct(u16) {
        /// rightmost edge of window + 1
        right: u8 = 0,
        left: u8 = 0,
    };

    pub const Vertical = packed struct(u16) {
        /// bottom-most edge of window + 1
        bottom: u8 = 0,
        top: u8 = 0,
    };

    h: [2]Horizontal align(2),
    v: [2]Vertical align(2),
};

pub const bounds: *volatile Bounds = @ptrFromInt(gba.mem.io + 0x40);

pub const Layers = packed struct(u6) {
    bg0: Enable = .disable,
    bg1: Enable = .disable,
    bg2: Enable = .disable,
    bg3: Enable = .disable,
    obj: Enable = .disable,
    color_sfx: Enable = .disable,
};

pub const Control = extern struct {
    /// Controls for the area inside the coordinates specified by `horizontal[x]` and `vertical[x]`
    inner: [2]window.Layers align(1) = .{},
    /// Controls for the area not contained within any other window.
    outer: [2]window.Layers align(1) = .{},
    /// Controls for the non-transparent (palette index 1-15) pixels of any object
    /// with its `mode` attribute set to `.obj_window`.
    obj: window.Layers align(1) = .{},
};

/// Window controls
///
/// (`REG_WINCNT`)
pub const ctrl: *window.Control = @ptrFromInt(gba.mem.io + 0x48);
