const mem = @import("mem.zig");

pub const width = 240;
pub const height = 160;

pub const DisplayMode = enum(u3) {
    mode0,
    mode1,
    mode2,
    mode3,
    mode4,
    mode5,
};

pub const ObjCharacterMapping = enum(u1) {
    two_dim,
    one_dim,
};

pub const Visiblity = enum(u1) {
    hide,
    show,
};

pub const DisplayControl = packed struct {
    mode: DisplayMode = .mode0,
    gameBoyColorMode: bool = false,
    pageSelect: u1 = 0,
    oamAccessDuringHBlank: bool = false,
    objVramCharacterMapping: ObjCharacterMapping = .two_dim,
    forcedBlank: bool = false,
    backgroundLayer0: Visiblity = .hide,
    backgroundLayer1: Visiblity = .hide,
    backgroundLayer2: Visiblity = .hide,
    backgroundLayer3: Visiblity = .hide,
    objectLayer: Visiblity = .hide,
    showWindow0: Visiblity = .hide,
    showWindow1: Visiblity = .hide,
    showObjWindow: Visiblity = .hide,
};

pub const Enabled =  enum(u1) {
    disabled,
    enabled,
};

pub const DisplayStatus = packed struct {
    in_vblank: bool = false,
    in_hblank: bool = false,
    in_vcount: bool = false,
    vblank_irq: Enabled = .disabled,
    hblank_irq: Enabled = .disabled,
    vcount_irg: Enabled = .disabled,
    unused0: bool = false,
    unused1: bool = false,
};

pub fn toRgb16(red: u5, green: u5, blue: u5) u16 {
    return @as(u16, red) | (@as(u16, green) << 5) | (@as(u16, blue) << 10);
}

pub fn pixelIndex(x: u8, y: u8) u16 {
    return @intCast(u16, y) * width + x;
}
