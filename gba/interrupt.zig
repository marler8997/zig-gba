const mem = @import("mem.zig");

pub const vblank          : u16 = 0x0001;
pub const hblank          : u16 = 0x0002;
pub const vcounter        : u16 = 0x0004;
pub const timer0_overflow : u16 = 0x0008;
pub const timer1_overflow : u16 = 0x0010;
pub const timer2_overflow : u16 = 0x0020;
pub const timer3_overflow : u16 = 0x0040;
pub const serial_com      : u16 = 0x0080;
pub const dma0            : u16 = 0x0100;
pub const dma1            : u16 = 0x0200;
pub const dma2            : u16 = 0x0400;
pub const dma3            : u16 = 0x0800;
pub const keypad          : u16 = 0x1000;
pub const game_pak        : u16 = 0x2000;

pub const count = 15;

const InterruptTableEntry = packed struct {
    handler: fn() void,
    mask: u32,
};

export var interrupt_table: [count]InterruptTableEntry = undefined;

fn defaultInterruptHandler() void { }

pub fn init() void {
    for (interrupt_table) |*entry| {
        entry.* = .{
            .handler = defaultInterruptHandler,
            .mask = 0,
        };
    }
    mem.reg_ime.* = 0;
    mem.reg_interrupt.* = interruptHandler;
    //mem.reg_dispstat.* |= .{ .vblank_irq
    //    
    //};
}


// NOTE: this is ARM 32-bit code instead of thumb
pub fn interruptHandler() callconv(.Naked) void {
    // switch to thumb mode
    asm volatile (
        \\.arm
        \\.cpu arm7tdmi
        \\adr r0, thumb_handler+1
        \\bx r0
        \\thumb_handler:
    );

    // TODO: save r4 - r11 if the handler will be using them

    // right now just handle VBLANK
    // assert(mem.reg_if.* == vblank)
    mem.reg_if.* = vblank; // acknowledge the interrupt
    mem.reg_ifbios.* |= 1;

    // switch back to arm mode and return
    asm volatile (
        \\.thumb
        \\bx lr
    );
}
