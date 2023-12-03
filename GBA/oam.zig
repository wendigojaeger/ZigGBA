const GBA = @import("core.zig").GBA;

pub const OAM = struct {
    pub const ObjMode = enum(u2) {
        Normal,
        SemiTransparent,
        ObjWindow,
    };

    pub const FlipSettings = packed struct {
        dummy: u3 = 0,
        horizontalFlip: u1 = 0,
        verticalFlip: u1 = 0,
    };

    pub const ObjectSize = enum {
        Size8x8,
        Size16x8,
        Size8x16,
        Size16x16,
        Size32x8,
        Size8x32,
        Size32x32,
        Size32x16,
        Size16x32,
        Size64x64,
        Size64x32,
        Size32x64,
    };

    pub const ObjectShape = enum(u2) {
        Square,
        Horizontal,
        Vertical,
    };

    pub const Attribute = packed struct {
        y: u8 = 0,
        rotationScaling: bool = false,
        doubleSizeOrVisible: bool = false,
        mode: ObjMode = .Normal,
        mosaic: bool = false,
        paletteMode: GBA.PaletteMode = .Color16,
        shape: ObjectShape = .Square,
        x: u9 = 0,
        flip: FlipSettings = FlipSettings{},
        size: u2 = 0,
        tileIndex: u10 = 0,
        priority: u2 = 0,
        palette: u4 = 0,
        dummy: i16 = 0,

        const Self = @This();

        pub fn setSize(self: *Self, size: ObjectSize) void {
            switch (size) {
                .Size8x8 => {
                    self.shape = .Square;
                    self.size = 0;
                },
                .Size16x8 => {
                    self.shape = .Horizontal;
                    self.size = 0;
                },
                .Size8x16 => {
                    self.shape = .Vertical;
                    self.size = 0;
                },
                .Size16x16 => {
                    self.shape = .Square;
                    self.size = 1;
                },
                .Size32x8 => {
                    self.shape = .Horizontal;
                    self.size = 1;
                },
                .Size8x32 => {
                    self.shape = .Vertical;
                    self.size = 1;
                },
                .Size32x32 => {
                    self.shape = .Square;
                    self.size = 2;
                },
                .Size32x16 => {
                    self.shape = .Horizontal;
                    self.size = 2;
                },
                .Size16x32 => {
                    self.shape = .Vertical;
                    self.size = 2;
                },
                .Size64x64 => {
                    self.shape = .Square;
                    self.size = 3;
                },
                .Size64x32 => {
                    self.shape = .Horizontal;
                    self.size = 3;
                },
                .Size32x64 => {
                    self.shape = .Vertical;
                    self.size = 3;
                },
            }
        }

        pub inline fn setRotationParameterIndex(self: *Self, index: u5) void {
            self.flip = @as(FlipSettings, @bitCast(index));
        }

        pub inline fn setTileIndex(self: *Self, tileIndex: i32) void {
            @setRuntimeSafety(false);
            self.tileIndex = @as(u10, @intCast(tileIndex));
        }

        pub inline fn setPosition(self: *Self, x: i32, y: i32) void {
            @setRuntimeSafety(false);
            self.x = @as(u9, @intCast(x));
            self.y = @as(u8, @intCast(y));
        }

        pub fn getAffine(self: Self) *Affine {
            const affine_index = @as(u5, @bitCast(self.flip));
            return &affineBuffer[affine_index];
        }
    };

    pub const Affine = extern struct {
        fill0: [3]u16 align(1),
        pa: i16 align(1),
        fill1: [3]u16 align(1),
        pb: i16 align(1),
        fill2: [3]u16 align(1),
        pc: i16 align(1),
        fill3: [3]u16 align(1),
        pd: i16 align(1),

        const Self = @This();

        pub fn setIdentity(self: *Self) void {
            self.pa = 0x0100;
            self.pb = 0;
            self.pc = 0;
            self.pd = 0x0100;
        }
    };

    const OAMAttributePtr = @as([*]align(4) volatile Attribute, @ptrCast(@alignCast(GBA.OAM)));
    const OAMAttribute = OAMAttributePtr[0..128];

    var attributeBuffer: [128]Attribute = undefined;
    var currentAttribute: usize = 0;

    const affineBufferPtr = @as([*]align(4) Affine, @ptrCast(&attributeBuffer));
    const affineBuffer = affineBufferPtr[0..32];

    pub fn init() void {
        for (&attributeBuffer) |*attribute| {
            attribute.* = Attribute{};
        }
    }

    pub fn allocate() *Attribute {
        const result = &attributeBuffer[currentAttribute];
        currentAttribute += 1;
        return result;
    }

    pub fn update(count: usize) void {
        var index: usize = 0;
        while (index < count) : (index += 1) {
            OAMAttribute[index] = attributeBuffer[index];
        }
        currentAttribute = 0;
    }
};
