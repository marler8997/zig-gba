const ops = @import("ops.zig");
const bios = @import("bios.zig");
const root = @import("root");

comptime {
    _ = @import("header.zig"); // This forces header.zig to be imported
    if (!@hasDecl(root, "_start")) {
        @export(_start, .{ .name = "_start", .section = ".gbamain" });
    }
}

extern var __bss_lma: u8;
extern var __bss_start__: u8;
extern var __bss_end__: u8;
extern var __data_lma: u8;
extern var __data_start__: u8;
extern var __data_end__: u8;

fn _start() callconv(.Naked) noreturn {
    // Assembly init code
    asm volatile (
        \\.arm
        \\.cpu arm7tdmi
        \\mov r0, #0x4000000
        \\str r0, [r0, #0x208]
        \\
        \\mov r0, #0x12
        \\msr cpsr, r0
        \\ldr sp, =__sp_irq
        \\mov r0, #0x1f
        \\msr cpsr, r0
        \\ldr sp, =__sp_usr
        \\add r0, pc, #1
        \\bx r0
    );

    bios.registerRamReset(bios.RamResetFlags.All);

    // Clear .bss
    ops.memset32(@ptrCast([*]volatile u8, &__bss_start__), 0, @ptrToInt(&__bss_end__) - @ptrToInt(&__bss_start__));

    // Copy .data section to EWRAM
    ops.memcpy32(@ptrCast([*]volatile u8, &__data_start__), @ptrCast([*]const u8, &__data_lma), @ptrToInt(&__data_end__) - @ptrToInt(&__data_start__));

    if (@typeInfo(@TypeOf(root.main)).Fn.return_type != noreturn)
        @compileError("expected return type of main to be 'noreturn'");

    @call(.{ .modifier = .always_inline }, root.main, .{});
}
