//! Example ported from: http://www.loirak.com/gameboy/gbatutor.php
//!
//! Gameboy Advance Tutorial - Loirak Developmen
//!
const gba = @import("gba");
const mem = gba.mem;
const gfx = gba.gfx;
const mode3 = gba.mode3;

// NOTE: this is required unless we find a solution for: https://github.com/ziglang/zig/issues/8508
comptime { _ = gba.start; }

// NOTE: I'd like to export this in header.zig but when I export it that way
//       it says it requires the struct to be 'extern'
//       https://github.com/ziglang/zig/issues/8501
export const _ linksection(".gbaheader") = gba.Header.init("HI", "AFSE", "00", 0);

pub fn main() noreturn {
    mem.reg_dispcnt_l.* = gfx.DisplayControl{
        .mode = .mode3,
        .backgroundLayer2 = .show,
    };

    // clear screen, and draw a blue background
    {
        var x: u8 = 0;
        while (x < gfx.width) : (x += 1) {
            var y: u8 = 0;
            while (y < gfx.height) : (y += 1) {
                mode3.video[gfx.pixelIndex(x, y)] = gfx.toRgb16(0, 0, 31);
            }
        }
    }

    // draw a white HI on the background
    {
        var x: u8 = 20;
        while (x <= 60) : (x += 15) {
            var y: u8 = 30;
            while (y < 50) : (y += 1) {
                mode3.video[gfx.pixelIndex(x, y)] = gfx.toRgb16(31, 31, 31);
            }
        }
    }
    {
        var x: u8 = 20;
        while (x <= 35) : (x += 1) {
            mode3.video[gfx.pixelIndex(x, 40)] = gfx.toRgb16(31, 31, 31);
        }
    }

    while (true) {} // loop forever
}
