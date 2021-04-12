const root = @import("root");

// TODO: this doesn't work because of:
//     https://github.com/ziglang/zig/issues/8501 (@export doesn't work with packed structs)
//
//comptime {
//    //if (!@hasDecl(root, "gbaheader"))
//    //    @compileError("roo"
//    @export(root.gbaheader, .{ .name = "__gbaheader__", .section = ".gbaheader" });
//}

pub const Header = packed struct {
    romEntryPoint: u32,
    nintendoLogo: [156]u8,
    gameName: [12]u8,
    gameCode: [4]u8,
    makerCode: [2]u8,
    fixedValue: u8,
    mainUnitCode: u8,
    deviceType: u8,
    reservedArea: [7]u8,
    softwareVersion: u8,
    complementCheck: u8,
    reservedArea2: [2]u8,

    pub fn init(comptime gameName: []const u8, comptime gameCode: []const u8, comptime makerCode: ?[]const u8, comptime softwareVersion: ?u8) Header {
        var header = Header{
            .romEntryPoint = 0xEA00002E,
            .nintendoLogo = .{
                0x24, 0xFF, 0xAE, 0x51, 0x69, 0x9A, 0xA2, 0x21, 0x3D, 0x84, 0x82, 0x0A, 0x84, 0xE4, 0x09, 0xAD,
                0x11, 0x24, 0x8B, 0x98, 0xC0, 0x81, 0x7F, 0x21, 0xA3, 0x52, 0xBE, 0x19, 0x93, 0x09, 0xCE, 0x20,
                0x10, 0x46, 0x4A, 0x4A, 0xF8, 0x27, 0x31, 0xEC, 0x58, 0xC7, 0xE8, 0x33, 0x82, 0xE3, 0xCE, 0xBF,
                0x85, 0xF4, 0xDF, 0x94, 0xCE, 0x4B, 0x09, 0xC1, 0x94, 0x56, 0x8A, 0xC0, 0x13, 0x72, 0xA7, 0xFC,
                0x9F, 0x84, 0x4D, 0x73, 0xA3, 0xCA, 0x9A, 0x61, 0x58, 0x97, 0xA3, 0x27, 0xFC, 0x03, 0x98, 0x76,
                0x23, 0x1D, 0xC7, 0x61, 0x03, 0x04, 0xAE, 0x56, 0xBF, 0x38, 0x84, 0x00, 0x40, 0xA7, 0x0E, 0xFD,
                0xFF, 0x52, 0xFE, 0x03, 0x6F, 0x95, 0x30, 0xF1, 0x97, 0xFB, 0xC0, 0x85, 0x60, 0xD6, 0x80, 0x25,
                0xA9, 0x63, 0xBE, 0x03, 0x01, 0x4E, 0x38, 0xE2, 0xF9, 0xA2, 0x34, 0xFF, 0xBB, 0x3E, 0x03, 0x44,
                0x78, 0x00, 0x90, 0xCB, 0x88, 0x11, 0x3A, 0x94, 0x65, 0xC0, 0x7C, 0x63, 0x87, 0xF0, 0x3C, 0xAF,
                0xD6, 0x25, 0xE4, 0x8B, 0x38, 0x0A, 0xAC, 0x72, 0x21, 0xD4, 0xF8, 0x07,
            },
            .gameName = [_]u8{0} ** 12,
            .gameCode = [_]u8{0} ** 4,
            .makerCode = [_]u8{0} ** 2,
            .fixedValue = 0x96,
            .mainUnitCode = 0x00,
            .deviceType = 0x00,

            .reservedArea = [_]u8{0} ** 7,
            .softwareVersion = 0x00,
            .complementCheck = 0x00,
            .reservedArea2 = [_]u8{0} ** 2,
        };

        comptime {
            const isUpper = @import("std").ascii.isUpper;
            const isDigit = @import("std").ascii.isDigit;

            for (gameName) |value, index| {
                var validChar = isUpper(value) or isDigit(value);

                if (validChar and index < 12) {
                    header.gameName[index] = value;
                } else {
                    if (index >= 12) {
                        @compileError("Game name is too long, it needs to be no longer than 12 characters.");
                    } else if (!validChar) {
                        @compileError("Game name needs to be in uppercase, it can use digits.");
                    }
                }
            }

            for (gameCode) |value, index| {
                var validChar = isUpper(value);

                if (validChar and index < 4) {
                    header.gameCode[index] = value;
                } else {
                    if (index >= 4) {
                        @compileError("Game code is too long, it needs to be no longer than 4 characters.");
                    } else if (!validChar) {
                        @compileError("Game code needs to be in uppercase.");
                    }
                }
            }

            if (makerCode) |mCode| {
                for (mCode) |value, index| {
                    var validChar = isDigit(value);
                    if (validChar and index < 2) {
                        header.makerCode[index] = value;
                    } else {
                        if (index >= 2) {
                            @compileError("Maker code is too long, it needs to be no longer than 2 characters.");
                        } else if (!validChar) {
                            @compileError("Maker code needs to be digits.");
                        }
                    }
                }
            }

            header.softwareVersion = softwareVersion orelse 0;

            var complementCheck: u8 = 0;
            var index: usize = 0xA0;

            const computeCheckData = @as([]const u8, @ptrCast(*[192]u8, &header));
            while (index < 0xA0 + (0xBD - 0xA0)) : (index += 1) {
                complementCheck +%= computeCheckData[index];
            }

            var tempCheck = -(0x19 + @intCast(i32, complementCheck));
            header.complementCheck = @intCast(u8, tempCheck & 0xFF);
        }

        return header;
    }
};
