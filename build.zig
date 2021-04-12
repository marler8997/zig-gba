const std = @import("std");
const Builder = std.build.Builder;

const gbabuild = @import("gbabuild.zig");

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    _ = addGbaExe(b, mode, "hi");
}

fn addGbaExe(b: *Builder, mode: std.builtin.Mode, comptime name: []const u8) *std.build.LibExeObjStep {
    const exe = b.addExecutable(name, "examples/" ++ name ++ ".zig");
    exe.setLinkerScriptPath("gba.ld");
    exe.setTarget(gbabuild.thumb_target);
    exe.addPackagePath("gba", "gba.zig");
    exe.setBuildMode(mode);
    //exe.install();
    exe.installRaw(name ++ ".gba");
    return exe;
}
