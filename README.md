# Zig GBA

This is a work in progress SDK for creating Game Boy Advance games using [Zig](https://ziglang.org/) programming language. Once Zig has a proper package manager, I hope that it would as easy as import the ZigGBA package. Inspired by [TONC GBA tutorial](https://www.coranac.com/tonc/text/)

**This project is up for adoption for a new maintainer!**

## Setup

This project uses submodules, so post clone, you will need to run:

```bash
git submodule update --init
```

## Build

This library uses zig nominated [2024.3.0-mach](https://machengine.org/about/nominated-zig/). To install using [`zigup`](https://github.com/marler8997/zigup):

```sh
zigup 0.12.0-dev.3180+83e578a18
```

To build, simply use Zig's integrated build system
```bash
zig build
```

## First example running in a emulator

![First example emulator image](docs/images/FirstExampleEmulator.png)

## First example running on real hardware

![First example real hardware image](docs/images/FirstExampleRealHardware.png)