# Zig GBA

This is a work in progress SDK for creating Game Boy Advance games using [Zig](https://ziglang.org/) programming language. Once Zig has a proper package manager, I hope that it would as easy as import the ZigGBA package. Inspired by [TONC GBA tutorial](https://www.coranac.com/tonc/text/)

## Setup

This project uses submodules, so post clone, you will need to run:

```bash
git submodule update --init
```

## Build
This project assume current Zig master (0.11.0-dev.6533+d3c9bfada).

To build, simply use Zig's integrated build system
```bash
zig build
```

## First example running in a emulator

![First example emulator image](docs/images/FirstExampleEmulator.png)

## First example running on real hardware

![First example real hardware image](docs/images/FirstExampleRealHardware.png)