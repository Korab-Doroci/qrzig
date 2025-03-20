const std = @import("std");
const assert = std.debug.assert;

pub const ErrorCorrectionLevel = enum(u2) {
    L = 0b01,
    M = 0b00,
    Q = 0b11,
    H = 0b10,

    pub fn getOffset(self: ErrorCorrectionLevel) u2 {
        switch (self) {
            .L => return 0,
            .M => return 1,
            .Q => return 2,
            .H => return 3,
        }
    }
};

pub const EncodingMode = enum(u4) {
    numeric = 0b0001,
    alphanumeric = 0b0010,
    byte = 0b0100,
    kanji = 0b1000,

    pub fn getOffset(self: EncodingMode) u2 {
        switch (self) {
            .numeric => return 0,
            .alphanumeric => return 1,
            .byte => return 2,
            .kanji => return 3,
        }
    }
};

pub const VersionCapacityEntry = struct {
    error_correction: ErrorCorrectionLevel,
    encoding: EncodingMode,
    capacity: u16,
};

// Version 7 and up
pub const version_info_strings = [34]u18{
    0b00111110010010100,
    0b01000010110111100,
    0b01001101010011001,
    0b001010010011010011,
    0b001011101111110110,
    0b001100011101100010,
    0b001101100001000111,
    0b001110011000001101,
    0b001111100100101000,
    0b010000101101111000,
    0b010001010001011101,
    0b010010101000010111,
    0b010011010100110010,
    0b010100100110100110,
    0b010101011010000011,
    0b010110100011001001,
    0b010111011111101100,
    0b011000111011000100,
    0b011001000111100001,
    0b011010111110101011,
    0b011011000010001110,
    0b011100110000011010,
    0b011101001100111111,
    0b011110110101110101,
    0b011111001001010000,
    0b100000100111010101,
    0b100001011011110000,
    0b100010100010111010,
    0b100011011110011111,
    0b100100101100001011,
    0b100101010000101110,
    0b100110101001100100,
    0b100111010101000001,
    0b101000110001101001,
};

pub const Format_string = struct {
    error_correction: ErrorCorrectionLevel,
    pattern: u3,
    bits: u15,
};

pub const format_strings = [_]Format_string{
    .{ .error_correction = .L, .pattern = 0, .bits = 0b111011111000100 },
    .{ .error_correction = .L, .pattern = 1, .bits = 0b111001011110011 },
    .{ .error_correction = .L, .pattern = 2, .bits = 0b111110110101010 },
    .{ .error_correction = .L, .pattern = 3, .bits = 0b111100010011101 },
    .{ .error_correction = .L, .pattern = 4, .bits = 0b110011000101111 },
    .{ .error_correction = .L, .pattern = 5, .bits = 0b110001100011000 },
    .{ .error_correction = .L, .pattern = 6, .bits = 0b110110001000001 },
    .{ .error_correction = .L, .pattern = 7, .bits = 0b110100101110110 },
    .{ .error_correction = .M, .pattern = 0, .bits = 0b101010000010010 },
    .{ .error_correction = .M, .pattern = 1, .bits = 0b101000100100101 },
    .{ .error_correction = .M, .pattern = 2, .bits = 0b101111001111100 },
    .{ .error_correction = .M, .pattern = 3, .bits = 0b101101101001011 },
    .{ .error_correction = .M, .pattern = 4, .bits = 0b100010111111001 },
    .{ .error_correction = .M, .pattern = 5, .bits = 0b100000011001110 },
    .{ .error_correction = .M, .pattern = 6, .bits = 0b100111110010111 },
    .{ .error_correction = .M, .pattern = 7, .bits = 0b100101010100000 },
    .{ .error_correction = .Q, .pattern = 0, .bits = 0b011010101011111 },
    .{ .error_correction = .Q, .pattern = 1, .bits = 0b011000001101000 },
    .{ .error_correction = .Q, .pattern = 2, .bits = 0b011111100110001 },
    .{ .error_correction = .Q, .pattern = 3, .bits = 0b011101000000110 },
    .{ .error_correction = .Q, .pattern = 4, .bits = 0b010010010110100 },
    .{ .error_correction = .Q, .pattern = 5, .bits = 0b010000110000011 },
    .{ .error_correction = .Q, .pattern = 6, .bits = 0b010111011011010 },
    .{ .error_correction = .Q, .pattern = 7, .bits = 0b010101111101101 },
    .{ .error_correction = .H, .pattern = 0, .bits = 0b001011010001001 },
    .{ .error_correction = .H, .pattern = 1, .bits = 0b001001110111110 },
    .{ .error_correction = .H, .pattern = 2, .bits = 0b001110011100111 },
    .{ .error_correction = .H, .pattern = 3, .bits = 0b001100111010000 },
    .{ .error_correction = .H, .pattern = 4, .bits = 0b000011101100010 },
    .{ .error_correction = .H, .pattern = 5, .bits = 0b000001001010101 },
    .{ .error_correction = .H, .pattern = 6, .bits = 0b000110100001100 },
    .{ .error_correction = .H, .pattern = 7, .bits = 0b000100000111011 },
};

pub const DataCodewordCapacityTable = [40][16]VersionCapacityEntry{
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 41 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 25 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 17 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 10 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 34 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 20 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 14 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 8 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 27 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 16 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 11 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 7 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 17 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 10 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 7 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 4 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 77 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 47 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 32 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 20 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 63 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 38 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 26 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 16 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 48 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 29 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 20 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 12 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 34 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 20 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 14 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 8 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 127 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 77 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 53 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 32 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 101 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 61 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 42 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 26 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 77 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 47 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 32 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 20 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 58 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 35 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 24 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 15 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 187 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 114 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 78 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 48 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 149 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 90 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 62 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 38 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 111 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 67 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 46 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 28 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 82 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 50 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 34 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 21 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 255 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 154 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 106 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 65 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 202 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 122 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 84 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 52 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 144 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 87 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 60 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 37 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 106 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 64 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 44 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 27 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 322 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 195 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 134 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 82 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 255 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 154 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 106 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 65 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 178 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 108 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 74 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 45 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 139 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 84 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 58 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 36 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 370 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 224 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 154 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 95 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 293 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 178 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 122 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 75 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 207 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 125 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 86 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 53 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 154 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 93 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 64 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 39 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 461 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 279 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 192 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 118 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 365 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 221 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 152 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 93 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 259 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 157 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 108 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 66 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 202 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 122 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 84 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 52 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 552 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 335 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 230 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 141 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 432 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 262 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 180 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 111 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 312 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 189 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 130 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 80 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 235 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 143 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 98 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 60 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 652 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 395 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 271 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 167 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 513 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 311 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 213 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 131 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 364 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 221 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 151 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 93 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 288 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 174 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 119 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 74 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 772 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 468 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 321 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 198 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 694 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 366 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 251 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 155 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 427 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 259 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 177 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 109 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 331 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 200 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 137 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 85 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 883 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 535 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 367 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 226 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 691 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 419 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 287 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 177 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 489 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 296 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 203 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 125 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 374 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 227 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 155 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 96 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 1022 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 619 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 425 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 262 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 796 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 483 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 331 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 204 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 580 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 352 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 241 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 149 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 427 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 259 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 177 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 109 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 1101 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 667 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 458 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 282 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 871 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 528 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 362 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 223 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 621 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 376 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 258 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 159 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 468 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 283 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 194 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 120 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 1250 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 758 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 520 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 320 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 991 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 600 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 412 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 254 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 703 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 426 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 292 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 180 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 530 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 321 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 220 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 136 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 1408 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 854 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 586 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 361 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 1082 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 656 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 450 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 277 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 775 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 470 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 322 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 198 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 602 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 365 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 250 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 154 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 1548 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 938 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 644 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 397 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 1212 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 734 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 504 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 310 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 876 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 531 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 364 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 224 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 674 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 408 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 280 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 173 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 1725 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 1046 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 718 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 442 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 1346 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 816 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 560 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 345 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 948 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 574 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 394 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 243 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 746 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 452 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 310 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 191 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 1903 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 1153 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 792 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 488 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 1500 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 909 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 624 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 384 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 1063 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 644 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 442 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 272 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 813 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 493 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 338 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 208 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 2061 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 1249 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 858 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 528 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 1600 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 970 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 666 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 410 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 1159 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 702 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 482 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 297 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 919 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 557 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 382 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 235 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 2232 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 1352 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 929 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 572 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 1708 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 1035 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 711 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 438 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 1224 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 742 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 509 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 314 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 969 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 587 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 403 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 248 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 2409 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 1460 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 1003 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 618 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 1872 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 1134 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 779 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 480 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 1358 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 823 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 565 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 348 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 1056 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 640 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 439 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 270 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 2620 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 1588 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 1091 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 672 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 2059 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 1248 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 857 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 528 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 1468 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 890 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 611 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 376 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 1108 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 672 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 461 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 284 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 2812 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 1704 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 1171 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 721 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 2188 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 1326 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 911 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 561 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 1588 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 963 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 661 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 407 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 1228 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 744 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 511 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 315 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 3057 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 1853 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 1273 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 784 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 2395 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 1451 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 997 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 614 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 1718 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 1041 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 715 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 440 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 1286 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 779 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 535 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 330 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 2383 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 1990 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 1367 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 842 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 2544 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 1542 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 1059 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 652 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 1804 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 1094 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 751 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 462 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 1425 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 864 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 593 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 365 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 3517 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 2132 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 1465 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 902 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 2701 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 1637 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 1125 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 692 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 1933 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 1172 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 805 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 496 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 1501 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 910 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 625 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 385 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 3669 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 2223 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 1528 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 940 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 2857 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 1732 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 1190 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 732 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 2085 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 1263 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 868 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 534 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 1581 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 958 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 658 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 405 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 3909 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 2369 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 1628 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 1002 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 3035 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 1839 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 1264 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 778 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 2181 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 1322 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 908 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 559 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 1677 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 1016 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 698 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 430 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 4158 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 2520 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 1732 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 1066 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 3289 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 1994 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 1370 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 843 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 2358 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 1429 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 982 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 604 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 1782 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 1080 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 742 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 457 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 4417 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 2677 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 1840 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 1132 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 3486 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 2113 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 1452 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 894 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 2473 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 1499 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 1030 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 634 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 1897 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 1150 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 790 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 486 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 4686 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 2840 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 1952 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 1201 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 3693 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 2238 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 1538 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 947 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 2670 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 1618 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 1112 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 684 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 2022 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 1226 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 842 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 518 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 4965 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 3009 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 2068 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 1273 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 3909 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 2369 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 1628 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 1002 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 2805 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 1700 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 1168 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 719 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 2157 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 1307 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 898 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 553 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 5253 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 3183 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 2188 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 1347 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 4134 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 2506 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 1722 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 1060 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 2949 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 1787 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 1228 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 756 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 2301 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 1394 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 958 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 590 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 5529 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 3351 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 2303 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 1417 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 4343 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 2632 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 1809 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 1113 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 3081 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 1867 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 1283 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 790 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 2361 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 1431 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 983 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 605 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 5836 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 3537 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 2431 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 1496 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 4588 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 2780 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 1911 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 1176 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 3244 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 1966 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 1351 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 832 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 2524 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 1530 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 1051 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 647 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 6153 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 3729 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 2563 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 1577 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 4775 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 2894 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 1989 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 1224 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 3417 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 2071 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 1423 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 876 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 2625 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 1591 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 1093 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 673 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 6479 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 3927 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 2699 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 1661 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 5039 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 3054 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 2099 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 1292 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 3599 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 2181 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 1499 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 923 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 2735 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 1658 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 1139 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 701 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 6743 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 4087 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 2809 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 1729 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 5313 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 3220 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 2213 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 1362 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 3791 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 2298 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 1579 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 972 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 2927 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 1774 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 1219 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 750 },
    },
    [16]VersionCapacityEntry{
        .{ .error_correction = .L, .encoding = .numeric, .capacity = 7089 },
        .{ .error_correction = .L, .encoding = .alphanumeric, .capacity = 4296 },
        .{ .error_correction = .L, .encoding = .byte, .capacity = 2953 },
        .{ .error_correction = .L, .encoding = .kanji, .capacity = 1817 },
        .{ .error_correction = .M, .encoding = .numeric, .capacity = 5596 },
        .{ .error_correction = .M, .encoding = .alphanumeric, .capacity = 3391 },
        .{ .error_correction = .M, .encoding = .byte, .capacity = 2331 },
        .{ .error_correction = .M, .encoding = .kanji, .capacity = 1435 },
        .{ .error_correction = .Q, .encoding = .numeric, .capacity = 3993 },
        .{ .error_correction = .Q, .encoding = .alphanumeric, .capacity = 2420 },
        .{ .error_correction = .Q, .encoding = .byte, .capacity = 1663 },
        .{ .error_correction = .Q, .encoding = .kanji, .capacity = 1024 },
        .{ .error_correction = .H, .encoding = .numeric, .capacity = 3057 },
        .{ .error_correction = .H, .encoding = .alphanumeric, .capacity = 1852 },
        .{ .error_correction = .H, .encoding = .byte, .capacity = 1273 },
        .{ .error_correction = .H, .encoding = .kanji, .capacity = 784 },
    },
};

// Error correction

pub const MAX_DEGREE = 30;

pub const error_correction_codewords_per_block = [4][40]u8{
    .{ 7, 10, 15, 20, 26, 18, 20, 24, 30, 18, 20, 24, 26, 30, 22, 24, 28, 30, 28, 28, 28, 28, 30, 30, 26, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30 },
    .{ 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26, 26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28 },
    .{ 13, 22, 18, 26, 18, 24, 18, 22, 20, 24, 28, 26, 24, 20, 30, 24, 28, 28, 26, 30, 28, 30, 30, 30, 30, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30 },
    .{ 17, 28, 22, 16, 22, 28, 26, 26, 24, 28, 24, 28, 22, 24, 24, 30, 28, 28, 26, 28, 30, 24, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30 },
};

pub const num_error_correction_blocks = [4][40]u8{
    .{ 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 4, 6, 6, 6, 6, 7, 8, 8, 9, 9, 10, 12, 12, 12, 13, 14, 15, 16, 17, 18, 19, 19, 20, 21, 22, 24, 25 },
    .{ 1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 5, 8, 9, 9, 10, 10, 11, 13, 14, 16, 17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49 },
    .{ 1, 1, 2, 2, 4, 4, 6, 6, 8, 8, 8, 10, 12, 16, 12, 17, 16, 18, 21, 20, 23, 23, 25, 27, 29, 34, 34, 35, 38, 40, 43, 45, 48, 51, 53, 56, 59, 62, 65, 68 },
    .{ 1, 1, 2, 4, 4, 4, 5, 6, 8, 8, 11, 11, 16, 16, 18, 16, 19, 21, 25, 25, 25, 34, 30, 32, 35, 37, 40, 42, 45, 48, 51, 54, 57, 60, 63, 66, 70, 74, 77, 81 },
};

pub const log = [256]u8{ 0, 0, 1, 25, 2, 50, 26, 198, 3, 223, 51, 238, 27, 104, 199, 75, 4, 100, 224, 14, 52, 141, 239, 129, 28, 193, 105, 248, 200, 8, 76, 113, 5, 138, 101, 47, 225, 36, 15, 33, 53, 147, 142, 218, 240, 18, 130, 69, 29, 181, 194, 125, 106, 39, 249, 185, 201, 154, 9, 120, 77, 228, 114, 166, 6, 191, 139, 98, 102, 221, 48, 253, 226, 152, 37, 179, 16, 145, 34, 136, 54, 208, 148, 206, 143, 150, 219, 189, 241, 210, 19, 92, 131, 56, 70, 64, 30, 66, 182, 163, 195, 72, 126, 110, 107, 58, 40, 84, 250, 133, 186, 61, 202, 94, 155, 159, 10, 21, 121, 43, 78, 212, 229, 172, 115, 243, 167, 87, 7, 112, 192, 247, 140, 128, 99, 13, 103, 74, 222, 237, 49, 197, 254, 24, 227, 165, 153, 119, 38, 184, 180, 124, 17, 68, 146, 217, 35, 32, 137, 46, 55, 63, 209, 91, 149, 188, 207, 205, 144, 135, 151, 178, 220, 252, 190, 97, 242, 86, 211, 171, 20, 42, 93, 158, 132, 60, 57, 83, 71, 109, 65, 162, 31, 45, 67, 216, 183, 123, 164, 118, 196, 23, 73, 236, 127, 12, 111, 246, 108, 161, 59, 82, 41, 157, 85, 170, 251, 96, 134, 177, 187, 204, 62, 90, 203, 89, 95, 176, 156, 169, 160, 81, 11, 245, 22, 235, 122, 117, 44, 215, 79, 174, 213, 233, 230, 231, 173, 232, 116, 214, 244, 234, 168, 80, 88, 175 };

pub const exp = [256]u8{ 1, 2, 4, 8, 16, 32, 64, 128, 29, 58, 116, 232, 205, 135, 19, 38, 76, 152, 45, 90, 180, 117, 234, 201, 143, 3, 6, 12, 24, 48, 96, 192, 157, 39, 78, 156, 37, 74, 148, 53, 106, 212, 181, 119, 238, 193, 159, 35, 70, 140, 5, 10, 20, 40, 80, 160, 93, 186, 105, 210, 185, 111, 222, 161, 95, 190, 97, 194, 153, 47, 94, 188, 101, 202, 137, 15, 30, 60, 120, 240, 253, 231, 211, 187, 107, 214, 177, 127, 254, 225, 223, 163, 91, 182, 113, 226, 217, 175, 67, 134, 17, 34, 68, 136, 13, 26, 52, 104, 208, 189, 103, 206, 129, 31, 62, 124, 248, 237, 199, 147, 59, 118, 236, 197, 151, 51, 102, 204, 133, 23, 46, 92, 184, 109, 218, 169, 79, 158, 33, 66, 132, 21, 42, 84, 168, 77, 154, 41, 82, 164, 85, 170, 73, 146, 57, 114, 228, 213, 183, 115, 230, 209, 191, 99, 198, 145, 63, 126, 252, 229, 215, 179, 123, 246, 241, 255, 227, 219, 171, 75, 150, 49, 98, 196, 149, 55, 110, 220, 165, 87, 174, 65, 130, 25, 50, 100, 200, 141, 7, 14, 28, 56, 112, 224, 221, 167, 83, 166, 81, 162, 89, 178, 121, 242, 249, 239, 195, 155, 43, 86, 172, 69, 138, 9, 18, 36, 72, 144, 61, 122, 244, 245, 247, 243, 251, 235, 203, 139, 11, 22, 44, 88, 176, 125, 250, 233, 207, 131, 27, 54, 108, 216, 173, 71, 142, 1 };

pub fn mulGF256(a: u8, b: u8) u8 {
    if (a == 0 or b == 0) return 0;
    return exp[(@as(u16, @intCast(log[a])) + @as(u16, @intCast(log[b]))) % 255];
}

pub fn addGF256(a: u8, b: u8) u8 {
    return a ^ b;
}

pub fn getDivisor(degree: usize) []const u8 {
    std.debug.assert(degree >= 1 and degree <= MAX_DEGREE);

    return coefficient_table[degree][0..degree];
}

pub fn getGeneratorPolynomial(codewords: comptime_int) [codewords + 1]u8 {
    var prod: [codewords + 1]u8 = undefined;
    // Initialize prod array
    @memset(prod[codewords - 1 ..], 0);

    for (1..codewords) |i| {
        var j: usize = codewords - i - 1;
        while (j <= codewords) : (j += 1) {
            if (j == (codewords - i - 1)) {
                prod[j] = prod[j + 1];
            } else if (j == codewords) {
                prod[j] = @intCast((@as(usize, prod[j]) + i) % 255);
            } else {
                const x = exp[prod[j + 1]];
                const y = exp[@intCast((@as(usize, prod[j]) + i) % 255)];
                prod[j] = blk: {
                    @setEvalBranchQuota(100000);
                    for (exp, 0..) |exp_val, index| if (exp_val == x ^ y) break :blk @intCast(index);
                    break :blk 0;
                };
            }
        }
    }

    return prod;
}

// FIX MAY BE REDUNDANT CODE
// Multiply two polynomials in GF(256)
pub fn polyMulGF256(a: []u8, b: []u8) []u8 {
    var result: []u8 = .{0} ** (a.len + b.len - 1);
    for (0..a.len) |i| {
        for (0..b.len) |j| result[i + j] = addGF256(result[i + j], mulGF256(a[i], b[j]));
    }
    return result;
}

// FIX MAY BE REDUNDANT CODE
// Divide two polynomials in GF(256), returning the quotient and remainder
pub fn polyDivGF256(allocator: *std.mem.Allocator, dividend: []u8, divisor: []const u8) ![2][]u8 {
    var remainder = try allocator.alloc(u8, dividend.len);
    remainder = dividend;
    var quotient: [256]u8 = [_]u8{0} ** 256;

    // Perform long division
    while (remainder.len >= divisor.len) {
        const coeff = mulGF256(remainder[0], invGF256(divisor[0])); // Multiply by inverse of the leading term of divisor
        quotient[remainder.len - divisor.len] = coeff;

        // Subtract the divisor * coeff from the remainder
        for (0..divisor.len) |i| remainder[i] = addGF256(remainder[i], mulGF256(divisor[i], coeff));

        // Remove leading zeroes from remainder
        var non_zero_index: u8 = 0;
        while (non_zero_index < remainder.len and remainder[non_zero_index] == 0) non_zero_index += 1;
        remainder = remainder[non_zero_index..];
    }

    return [2][]u8{ quotient[0 .. dividend.len - divisor.len + 1], remainder };
}

// FIX MAY BE REDUNDANT CODE
// Compute the multiplicative inverse in GF(256)
pub fn invGF256(a: u8) u8 {
    if (a == 0) return 0;
    return exp[255 - log[a]];
}

pub const coefficient_table: [MAX_DEGREE][MAX_DEGREE]u8 = blk: {
    var table: [MAX_DEGREE][MAX_DEGREE]u8 = undefined;

    @setEvalBranchQuota(100000);

    for (1..MAX_DEGREE) |degree| {
        var result: [MAX_DEGREE]u8 = [_]u8{0} ** MAX_DEGREE;
        result[degree - 1] = 1;

        var root: u8 = 1;
        for (0..degree) |_| {
            for (0..degree) |i| {
                result[i] = mulGF256(result[i], root);
                if (i + 1 < degree) result[i] ^= result[i + 1];
            }
            root = mulGF256(root, 0x02);
        }

        table[degree] = result;
    }

    break :blk table;
};

// QR code

pub const Code = struct {
    version: u8,
    modules: [177][177]bool = .{.{false} ** 177} ** 177,
    ecl: ErrorCorrectionLevel,

    pub fn getSize(self: *Code) usize {
        return (self.version * 4) + 17;
    }
};

pub const num_data_modules_list: [40]u16 = blk: {
    var arr: [40]u16 = undefined;
    for (1..41) |version| {
        var result: u16 = (16 * version + 128) * version + 64;
        if (version >= 2) {
            const num_align = version / 7 + 2;
            result -= (25 * num_align - 10) * num_align - 55;
            if (version >= 7) result -= 36;
        }

        arr[version - 1] = result;
    }
    break :blk arr;
};
