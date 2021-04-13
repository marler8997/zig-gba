//! Example ported from: https://www.reinterpretcast.com/writing-a-game-boy-advance-game
//!
//! Issues Fixed
//! 1. Use a vblank interrupt instead of polling
//!
const std = @import("std");
const gba = @import("gba");
const mem = gba.mem;
const gfx = gba.gfx;
const input = gba.input;
const interrupt = gba.interrupt;

// NOTE: this is required unless we find a solution for: https://github.com/ziglang/zig/issues/8508
comptime { _ = gba.start; }

// NOTE: I'd like to export this in header.zig but when I export it that way
//       it says it requires the struct to be 'extern'
//       https://github.com/ziglang/zig/issues/8501
export const _ linksection(".gbaheader") = gba.Header.init("PONG", "AFSE", "00", 0);

const KEY_ANY  = 0x03FF;

const obj_attrs = packed struct {
    attr0: u16,
    attr1: u16,
    attr2: u16,
    pad: u16,
};
const tile_4bpp = [8]u32;
const tile_block = [512]tile_4bpp;

const oam_mem = @ptrCast([*]volatile obj_attrs, mem.oam);
const tile_mem = @ptrCast([*]volatile tile_block, mem.video16);

// Set the position of an object to specified x and y coordinates
fn set_object_position(object: *volatile obj_attrs, x: u9, y: u8) void {
    const attr0_y_mask: u16 = 0x0FF;
    const attr1_x_mask: u16 = 0x1FF;

    // TODO: assert if x/y is out of range?
    object.attr0 = (object.attr0 & ~attr0_y_mask) | (y & attr0_y_mask);
    object.attr1 = (object.attr1 & ~attr1_x_mask) | (x & attr1_x_mask);
}

fn min(comptime T: type, a: T, b: T) T {
    return if (a <= b) a else b;
}

fn subtractClampToZero(comptime T: type, value: T, subtract: T) T {
    return value - min(T, value, subtract);
}

fn clampMax(comptime T: type, val: T, max: T) T {
    return if (val > max) max else val;
}

fn SignedInt(comptime bits: comptime_int) type {
    return @Type(std.builtin.TypeInfo { .Int = .{
        .signedness = .signed,
        .bits = bits,
    }});
}

fn addSignedClamp(comptime T: type, val: T, add: SignedInt(@typeInfo(T).Int.bits), max: T) T {
    return if (add >= 0) clampMax(T, val + @intCast(u8, add), max) else
        subtractClampToZero(T, val, @intCast(T, -add));
}

pub fn main() noreturn {
    

    // Write the tiles for our sprites into the fourth tile block in VRAM.
    // Four tiles for an 8x32 paddle sprite, and one tile for an 8x8 ball
    // sprite. Using 4bpp, 0x1111 is four pixels of colour index 1, and
    // 0x2222 is four pixels of colour index 2.
    //
    // NOTE: We're using our own memory writing code here to avoid the
    // byte-granular writes that something like 'memset' might make (GBA
    // VRAM doesn't support byte-granular writes).
    const paddle_tile_mem = @ptrCast([*] volatile u16, &tile_mem[4][1]);
    const ball_tile_mem   = @ptrCast([*] volatile u16, &tile_mem[4][5]);
    { var i: usize = 0; while (i < 4 * (@sizeOf(tile_4bpp) / 2)) : (i += 1) {
        paddle_tile_mem[i] = 0x1111; // 0b_0001_0001_0001_0001
    }}
    { var i: usize = 0; while (i < @sizeOf(tile_4bpp) / 2) : (i += 1) {
        ball_tile_mem[i] = 0x2222;   // 0b_0002_0002_0002_0002
    }}

    // Write the colour palette for our sprites into the first palette of
    // 16 colours in colour palette memory (this palette has index 0)
    mem.obj_palette[1] = gfx.toRgb16(0x1F, 0x1F, 0x1F); // White
    mem.obj_palette[2] = gfx.toRgb16(0x1F, 0x00, 0x1F); // Magenta

    // Create our sprites by writing their object attributes into OAM
    // memory
    const paddle_attrs = &oam_mem[0];
    paddle_attrs.attr0 = 0x8000; // 4bpp tiles, TALL shape
    paddle_attrs.attr1 = 0x4000; // 8x32 size when using the TALL shape
    paddle_attrs.attr2 = 1;      // Start at the first tile in tile
                                 // block four, use color palette zero
    const ball_attrs = &oam_mem[1];
    ball_attrs.attr0 = 0; // 4bpp tiles, SQUARE shape
    ball_attrs.attr1 = 0; // 8x8 size when using the SQUARE shape
    ball_attrs.attr2 = 5; // Start at the fifth tile in tile block four,
                          // use color palette zero

    // Initialize variables to keep track of the state of the paddle and
    // ball, and set their initial positions (by modifying their
    // attributes in OAM)
    const player_width = 8;
    const player_height = 32;
    const ball_width = 8;
    const ball_height = 8;
    const player_velocity = 2;
    var ball_velocity_x: i8 = 2;
    var ball_velocity_y: i8 = 1;
    const player_x = 5;
    var player_y: u8 = 96;
    var ball_x: u8 = 22;
    var ball_y: u8 = 96;
    set_object_position(paddle_attrs, player_x, player_y);
    set_object_position(ball_attrs, ball_x, ball_y);

    mem.reg_dispcnt_l.* = gfx.DisplayControl{
        .objVramCharacterMapping = .one_dim,
        .objectLayer = .show,
    };
    
    interrupt.init();
    mem.reg_dispstat.* = gfx.DisplayStatus { .vblank_irq = .enabled };
    mem.reg_ie.* |= interrupt.vblank;
    // NOTE: comment this out to disable interrupt handling for now
    //mem.reg_ime.* = 1;

    // The main game loop
    while (true) {
        // Skip past the rest of any current V-Blank, then skip past
        // the V-Draw
        // NOTE: this is a bad way to handle vsync, use the vblank interrupt instead
        while (mem.reg_vcount.* >= 160) { }
        while (mem.reg_vcount.* < 160) { }

        //asm volatile("swi 0x05"); // wait for vblank

        // Get current key states (REG_KEY_INPUT stores the states
        // inverted)
        const key_states = (~(mem.reg_p1.*)) & KEY_ANY;

        // Note that our physics update is tied to the framerate,
        // which isn't generally speaking a good idea. Also, this is
        // really terrible physics and collision handling code.
        const player_max_clamp_y = gfx.height - player_height;
        if ((key_states & input.Key.up) != 0)
            player_y = subtractClampToZero(u8, player_y, player_velocity);
        if ((key_states & input.Key.down) != 0)
            player_y = clampMax(u8, player_y + player_velocity, player_max_clamp_y);

        // NOTE: this if condition is probably unnecessary and could be making the code slower
        if (((key_states & input.Key.up) != 0) or ((key_states & input.Key.down) != 0))
            set_object_position(paddle_attrs, player_x, player_y);

        const ball_max_clamp_x: c_int = gfx.width  - ball_width;
        const ball_max_clamp_y: c_int = gfx.height - ball_height;
        if ((ball_x >= player_x and ball_x <= player_x + player_width) and
            (ball_y >= player_y and ball_y <= player_y + player_height)) {
            ball_x = player_x + player_width;
            ball_velocity_x = -ball_velocity_x;
        } else {
            if (ball_x == 0 or ball_x == ball_max_clamp_x)
                ball_velocity_x = -ball_velocity_x;
            if (ball_y == 0 or ball_y == ball_max_clamp_y)
                ball_velocity_y = -ball_velocity_y;
        }

        ball_x = addSignedClamp(u8, ball_x, ball_velocity_x, ball_max_clamp_x);
        ball_y = addSignedClamp(u8, ball_y, ball_velocity_y, ball_max_clamp_y);
        set_object_position(ball_attrs, ball_x, ball_y);
    }
}
