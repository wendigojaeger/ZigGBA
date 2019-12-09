# Zig GBA "Hello World"

This is a simple GBA program that display 3 color pixel as a hello world to the system. Also a testament to the Zig excellent cross-compile functionality !

## Build
This project assume current Zig master (0.5.0+d28aa38db). For now, you need llvm-objcopy in your PATH or change the hardcoded path in build.zig.

To build, simply use Zig's integrated build system
```Shell
zig build
```

## Running in a emulator

![Emulator image](docs/Emulator.png)

## Running on real hardware

![Real hardware image](docs/RealHardware.png)