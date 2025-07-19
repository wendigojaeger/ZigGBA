# Zig GBA

This is a work in progress SDK for creating Game Boy Advance games using the [Zig](https://ziglang.org/) programming language. Once Zig has a proper package manager, I hope that it would as easy as import the ZigGBA package. Inspired by [TONC GBA tutorial](https://gbadev.net/tonc/)

## Setup

This project uses submodules, so post clone, you will need to run:

```bash
git submodule update --init
```

## Build

This library currently uses Zig 0.14.1.

The tool [`anyzig`](https://github.com/marler8997/anyzig) is recommended for managing Zig installations.

To build the examples with `anyzig` installed, clone this repository and use Zig's integrated build system like so in the root ZigGBA directory:

```bash
zig build
```

This will write output ROMs to `zig-out/bin/`. These are files with a `*.gba` extension which can be written to a GBA cartridge or which can run in emulators such as [mGBA](https://github.com/mgba-emu/mgba), [Mesen](https://github.com/SourMesen/Mesen2/), and [NanoBoyAdvance](https://github.com/nba-emu/NanoBoyAdvance).

## First example running in a emulator

![First example emulator image](docs/images/FirstExampleEmulator.png)

## First example running on real hardware

![First example real hardware image](docs/images/FirstExampleRealHardware.png)
