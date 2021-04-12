pub const mem = @import("gba/mem.zig");
pub const gfx = @import("gba/gfx.zig");
pub const header = @import("gba/header.zig");
pub const Header = header.Header;
pub const ops = @import("gba/ops.zig");
pub const bios = @import("gba/bios.zig");
pub const start = @import("gba/start.zig");

// This forces header.zig and start.zig to be imported
comptime {
    _ = header;
    _ = start;
}
