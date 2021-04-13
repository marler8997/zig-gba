const std = @import("std");
const Builder = std.build.Builder;

const gbabuild = @import("gbabuild.zig");

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    _ = addGbaExe(b, mode, "hi");
    _ = addGbaExe(b, mode, "display");
    _ = addGbaExe(b, mode, "pong");
    _ = addGbaExe(b, mode, "pongbetter");
}

fn addGbaExe(b: *Builder, mode: std.builtin.Mode, comptime name: []const u8) *std.build.LibExeObjStep {
    const exe = b.addExecutable(name, "examples/" ++ name ++ ".zig");
    exe.setLinkerScriptPath("gba.ld");
    exe.setTarget(gbabuild.thumb_target);
    exe.addPackagePath("gba", "gba.zig");
    exe.setBuildMode(mode);
    exe.installRaw(name ++ ".gba");
    return exe;
}
