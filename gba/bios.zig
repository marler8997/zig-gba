const std = @import("std");

pub const RamResetFlags = packed struct {
    clearEwRam: bool = false,
    clearIwram: bool = false,
    clearPalette: bool = false,
    clearVRAM: bool = false,
    clearOAM: bool = false,
    resetSIORegisters: bool = false,
    resetSoundRegisters: bool = false,
    resetOtherRegisters: bool = false,

    const Self = @This();

    pub const All = Self{
        .clearEwRam = true,
        .clearIwram = true,
        .clearPalette = true,
        .clearVRAM = true,
        .clearOAM = true,
        .resetSIORegisters = true,
        .resetSoundRegisters = true,
        .resetOtherRegisters = true,
    };
};

fn getSystemCallAssemblyCode(comptime call: u8) callconv(.Inline) []const u8 {
    var buffer: [64]u8 = undefined;
    return std.fmt.bufPrint(buffer[0..], "swi {}", .{call}) catch unreachable;
}

pub fn systemCall1(comptime call: u8, param0: u32) callconv(.Inline) void {
    const assembly = comptime getSystemCallAssemblyCode(call);

    asm volatile (assembly
        :
        : [param0] "{r0}" (param0)
        : "r0"
    );
}

pub fn registerRamReset(flags: RamResetFlags) callconv(.Inline) void {
    systemCall1(0x01, @bitCast(u8, flags));
}
