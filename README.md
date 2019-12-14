# Zig GBA

This is a work in progress SDK for creating Game Boy Advance games using [Zig](https://ziglang.org/) programming language. Once Zig has a proper package manager, I hope that it would as easy as import the ZigGBA package. Inspired by [TONC GBA tutorial](https://www.coranac.com/tonc/text/)

## Build
This project assume current Zig master (0.5.0+a3f6a58c7). For now, you need llvm-objcopy in your PATH or change the hardcoded path in GBA/builder.zig.

To build, simply use Zig's integrated build system
```Shell
zig build
```

## First example running in a emulator

![First example emulator image](docs/images/FirstExampleEmulator.png)

## First example running on real hardware

![First example real hardware image](docs/images/FirstExampleRealHardware.png)