pub const mem = @import("gba/mem.zig");
pub const gfx = @import("gba/gfx.zig");
pub const mode3 = @import("gba/mode3.zig");
pub const mode4 = @import("gba/mode4.zig");
pub const header = @import("gba/header.zig");
pub const Header = header.Header;
pub const ops = @import("gba/ops.zig");
pub const input = @import("gba/input.zig");
pub const bios = @import("gba/bios.zig");
pub const start = @import("gba/start.zig");

// This forces header.zig and start.zig to be imported
comptime {
    _ = header;
    _ = start;
}
