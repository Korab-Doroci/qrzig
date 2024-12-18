const std = @import("std");
const assert = std.debug.assert;

const ECL = enum(u2) {
    L = 0b01,
    M = 0b00,
    Q = 0b11,
    H = 0b10,
};

const Mode = enum(u4) {
    numeric = 0b0001,
    alpha_numeric = 0b0010,
    byte = 0b0100,
    kanji = 0b1000,
};

const MAX_DEGREE = 30;

const error_correction_codewords_per_block = [4][40]u8{
    .{ 7, 10, 15, 20, 26, 18, 20, 24, 30, 18, 20, 24, 26, 30, 22, 24, 28, 30, 28, 28, 28, 28, 30, 30, 26, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30 },
    .{ 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26, 26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28 },
    .{ 13, 22, 18, 26, 18, 24, 18, 22, 20, 24, 28, 26, 24, 20, 30, 24, 28, 28, 26, 30, 28, 30, 30, 30, 30, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30 },
    .{ 17, 28, 22, 16, 22, 28, 26, 26, 24, 28, 24, 28, 22, 24, 24, 30, 28, 28, 26, 28, 30, 24, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30 },
};

const num_error_correction_blocks = [4][40]u8{
    .{ 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 4, 6, 6, 6, 6, 7, 8, 8, 9, 9, 10, 12, 12, 12, 13, 14, 15, 16, 17, 18, 19, 19, 20, 21, 22, 24, 25 },
    .{ 1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 5, 8, 9, 9, 10, 10, 11, 13, 14, 16, 17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49 },
    .{ 1, 1, 2, 2, 4, 4, 6, 6, 8, 8, 8, 10, 12, 16, 12, 17, 16, 18, 21, 20, 23, 23, 25, 27, 29, 34, 34, 35, 38, 40, 43, 45, 48, 51, 53, 56, 59, 62, 65, 68 },
    .{ 1, 1, 2, 4, 4, 4, 5, 6, 8, 8, 11, 11, 16, 16, 18, 16, 19, 21, 25, 25, 25, 34, 30, 32, 35, 37, 40, 42, 45, 48, 51, 54, 57, 60, 63, 66, 70, 74, 77, 81 },
};

pub const Code = struct {
    version: u8,
    modules: [177][177]bool = .{.{false} ** 177} ** 177,
    ecl: ECL,

    fn getSize(self: *Code) usize {
        return (self.version * 4) + 17;
    }
};

const num_data_modules_list: [40]u16 = blk: {
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

fn getSmallestVersion(num_code_words: usize) !u8 {
    for (num_data_modules_list, 0..) |num_data_modules, version| {
        if (num_data_modules / 8 >= num_code_words) return @intCast(version + 1);
    }
    return error.textTooBig;
}

pub fn generateTextCode(text: []const u8) !Code {
    const version = try getSmallestVersion(text.len);

    return Code{ .version = version, .ecl = .M };
}

fn generateFinderPattern(code: *Code, x: usize, y: usize) void {
    const pattern = [49]bool{
        true, true,  true,  true,  true,  true,  true,
        true, false, false, false, false, false, true,
        true, false, true,  true,  true,  false, true,
        true, false, true,  true,  true,  false, true,
        true, false, true,  true,  true,  false, true,
        true, false, false, false, false, false, true,
        true, true,  true,  true,  true,  true,  true,
    };

    for (pattern, 0..) |pattern_module, i| code.modules[y + i / 7][x + i % 7] = pattern_module;
}

fn generateAllFinderPatterns(code: *Code) void {
    const size = code.getSize();
    generateFinderPattern(code, 0, 0);
    generateFinderPattern(code, size - 7, 0);
    generateFinderPattern(code, 0, size - 7);
}

fn getAlignmentPatternPositions(version: u8) [7]usize {
    assert(version > 1 and version < 40);
    const num_align = version / 7 + 2;
    const step = (version * 8 + num_align * 3 + 5) / (num_align * 4 - 4) * 2;
    var i: usize = num_align - 1;
    var pos: usize = version * 4 + 10;
    var result: [7]usize = .{0} ** 7;
    while (i >= 1) : ({
        i -= 1;
        pos -= step;
    }) {
        result[i] = pos;
    }
    result[0] = 6;
    return result;
}

fn generateAlignmentPattern(code: *Code, x: usize, y: usize) void {
    const pattern = [25]bool{
        true, true,  true,  true,  true,
        true, false, false, false, true,
        true, false, true,  false, true,
        true, false, false, false, true,
        true, true,  true,  true,  true,
    };

    for (pattern, 0..) |p, i| code.modules[y + i / 5][x + i % 5] = p;
}

fn generateAllAlignmentPatterns(code: *Code) void {
    if (code.version <= 1 or code.version > 40) return;
    const alignment_positions = getAlignmentPatternPositions(code.version);
    const num_align = code.version / 7 + 2;
    const last_pos = alignment_positions[num_align - 1];
    for (alignment_positions) |y| {
        if (y < 2) continue;
        for (alignment_positions) |x| {
            if (x < 2 or (x == 6 and y == 6) or (x == last_pos and y == 6) or (x == 6 and y == last_pos)) continue;
            generateAlignmentPattern(code, x - 2, y - 2);
        }
    }
}

fn generateTimingPattern(code: *Code) void {
    const size = code.getSize();
    for (6..size - 6) |i| {
        if (i % 2 == 0) {
            code.modules[6][i] = true;
            code.modules[i][6] = true;
        }
    }
}

fn printCode(code: *Code) void {
    const size = code.getSize();
    for (0..size) |y| {
        for (0..size) |x| std.debug.print("{s}", .{if (code.modules[y][x]) "██" else "  "});
        std.debug.print("\n", .{});
    }
    std.debug.print("\n", .{});
}

fn generateDarkBit(code: *Code) void {
    code.modules[4 * code.version + 9][8] = true;
}

fn getFormatInfo(ec_level: ECL, mask_pattern: u3) u15 {
    const format_data: u15 = (@as(u15, @intFromEnum(ec_level)) << 3) | mask_pattern;

    const generator: u11 = 0b10100110111;
    var encoded: u15 = @as(u15, format_data) << 10;

    var i: u4 = 14;
    while (i >= 10) : (i -= 1) {
        if ((encoded & (@as(u15, 1) << i)) != 0) encoded ^= @as(u15, generator) << @intCast(i - 10);
    }

    encoded |= @as(u15, format_data) << 10;

    const mask: u15 = 0b101010000010010;
    return encoded ^ mask;
}

fn generateFormatInfo(code: *Code) void {
    // TODO FIX: ADD SUPPORT FOR VERSION 7 AND ABOVE
    assert(code.version < 7);
    const size = code.getSize();
    const mask: u3 = 0b1;
    const format_info = getFormatInfo(code.ecl, mask);

    for (0..8) |i| {
        const x_offset = if (i >= 6) i + 1 else i;
        code.modules[8][x_offset] = (format_info & (@as(u15, 1) << @intCast(14 - i))) != 0;
        code.modules[size - i - 1][8] = (format_info & (@as(u15, 1) << @intCast(14 - i))) != 0;
    }

    for (7..15) |i| {
        code.modules[8][size - 15 + i] = (format_info & (@as(u15, 1) << @intCast(14 - i))) != 0;
    }

    code.modules[7][8] = (format_info & (@as(u15, 1) << @intCast(6))) != 0;

    var i: usize = 6;
    while (i > 0) {
        i -= 1;
        code.modules[i][8] = (format_info & (@as(u15, 1) << @intCast(i))) != 0;
    }
}

fn getEncodingModeIndicator(string: []const u8) u4 {
    _ = string;
    // FIX ADD ALL ENCODING TYPES
    // Simplified version, assumes byte encoding for now
    return @intFromEnum(Mode.byte);
}

fn getEncodingBitCount(version: u8, mode: Mode) u8 {
    if (version <= 9) {
        switch (mode) {
            .numeric => return 10,
            .alpha_numeric => return 9,
            .byte => return 8,
            .kanji => return 8,
        }
    } else if (version <= 26) {
        switch (mode) {
            .numeric => return 12,
            .alpha_numeric => return 11,
            .byte => return 16,
            .kanji => return 10,
        }
    } else {
        switch (mode) {
            .numeric => return 14,
            .alpha_numeric => return 13,
            .byte => return 16,
            .kanji => return 12,
        }
    }
}

fn intToBuffer(comptime int: anytype) [@typeInfo(@TypeOf(int)).Int.bits]u1 {
    const bit_count = @typeInfo(@TypeOf(int)).Int.bits;
    var buffer: [bit_count]u1 = undefined;
    inline for (0..bit_count) |i| buffer[i] = @as(u1, @intCast((int >> bit_count - (i + 1)) & 1));

    return buffer;
}

fn groupBitsToBytes(input: []u1, comptime input_len: usize) [input_len]u8 {
    var result: [input_len]u8 = undefined;

    var i: usize = 0;
    while (i < input_len) {
        var byte: u8 = 0;
        var j: usize = 0;
        while (j < 8) {
            byte = (byte << 1) | input[i * 8 + j];
            j += 1;
        }
        result[i] = byte;
        i += 1;
    }

    return result;
}

fn getEncodedData(comptime string: []const u8) ![]u8 {
    const encoding_mode_indicator = @intFromEnum(Mode.byte);
    // FIX SUPPORT OTHER ENCODINGS AND VERSIONS THAN VERSION 1 - 9 FOR BYTE
    const encoding_bit_count = 8;
    const mode_indicator_bit_length = 4;

    var data_buffer: [string.len * 8 + mode_indicator_bit_length + encoding_bit_count]u1 = undefined;
    // idea for faster or more idiomatic way to write bits to buffer
    // const buffer_stream = std.io.fixedBufferStream(&data_buffer);
    // const bit_writer = std.io.bitWriter(.big, buffer_stream);
    @memcpy(data_buffer[0..4], &intToBuffer(encoding_mode_indicator));
    @memcpy(data_buffer[4 .. 4 + encoding_bit_count], &intToBuffer(@as(u8, @intCast(string.len * 8))));
    inline for (string, 0..) |char, i| {
        inline for (0..8) |bit| {
            data_buffer[4 + 8 + i * 8 + bit] = @as(u1, @intCast((char >> (7 - bit)) & 1));
        }
    }

    var encoded_data = groupBitsToBytes(&data_buffer, data_buffer.len / 8);

    return &encoded_data;
}

fn addPadding(code: *Code, encoded_data: []u8) []u8 {
    if (encoded_data.len + 6 >= num_data_modules_list[code.version - 1]) return encoded_data;

    var padded_data: [num_data_modules_list[code.version]]u8 = undefined;

    for (encoded_data.len..padded_data.len) |i| {
        if (i % 2 == 0) padded_data[i] = 0b11101100 else 0b0010001;
    }

    return encoded_data;
}

pub fn main() !void {
    const string = "Hello, world!";
    var code = try generateTextCode(string);
    generateTimingPattern(&code);
    generateAllFinderPatterns(&code);
    generateAllAlignmentPatterns(&code);
    generateDarkBit(&code);
    generateFormatInfo(&code);
    const encoded_data = try getEncodedData(string);
    _ = encoded_data;
    //addPadding(&code, encoded_data);
    printCode(&code);
}
