const std = @import("std");
const types = @import("types.zig");

// Code
const Code = types.Code;
const EncodingMode = types.EncodingMode;
const ErrorCorrectionLevel = types.ErrorCorrectionLevel;
const DataCodewordCapacityTable = types.DataCodewordCapacityTable;

// Error correction
const mulGF256 = types.mulGF256;
const addGF256 = types.addGF256;
const getDivisor = types.getDivisor;
const polyMulGF256 = types.polyMulGF256;
const polyDivGF256 = types.polyDivGF256;
const getGeneratorPolynomial = types.getGeneratorPolynomial;
const coefficient_table = types.coefficient_table;
const num_data_modules_list = types.num_data_modules_list;
const log = types.log;
const exp = types.exp;
const MAX_DEGREE = types.MAX_DEGREE;
const num_error_correction_blocks = types.num_error_correction_blocks;

// Debugging
const assert = std.debug.assert;

fn getSmallestVersion(num_code_words: usize) !u8 {
    for (num_data_modules_list, 0..) |num_data_modules, version| {
        if (num_data_modules / 8 >= num_code_words) return @intCast(version + 1);
    }
    return error.textTooBig;
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

fn getFormatInfo(ec_level: ErrorCorrectionLevel, mask_pattern: u3) u15 {
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

fn getEncodingModeIndicator() comptime_int {
    // FIX ADD ALL ENCODING TYPES
    // Simplified version, assumes byte encoding for now
    return @intFromEnum(EncodingMode.byte);
}

fn getEncodingBitCount(version: u8, mode: EncodingMode) comptime_int {
    if (version <= 9) {
        switch (mode) {
            .numeric => return 10,
            .alphanumeric => return 9,
            .byte => return 8,
            .kanji => return 8,
        }
    } else if (version <= 26) {
        switch (mode) {
            .numeric => return 12,
            .alphanumeric => return 11,
            .byte => return 16,
            .kanji => return 10,
        }
    } else {
        switch (mode) {
            .numeric => return 14,
            .alphanumeric => return 13,
            .byte => return 16,
            .kanji => return 12,
        }
    }
}

fn lookupDataCodewordCapacity(version: u8, encoding: EncodingMode, error_correction: ErrorCorrectionLevel) u16 {
    const offset = blk: {
        var error_offset: usize = 0;
        var encoding_offset: usize = 0;
        switch (error_correction) {
            .L => error_offset = 0,
            .M => error_offset = 4,
            .Q => error_offset = 8,
            .H => error_offset = 12,
        }
        switch (encoding) {
            .numeric => encoding_offset = 0,
            .alphanumeric => encoding_offset = 1,
            .byte => encoding_offset = 2,
            .kanji => encoding_offset = 3,
        }
        break :blk error_offset + encoding_offset;
    };
    return DataCodewordCapacityTable[version - 1][offset].capacity;
}

fn getEncodedData(comptime string: []const u8, comptime version: u8, comptime encoding: EncodingMode, comptime error_correction: ErrorCorrectionLevel) ![lookupDataCodewordCapacity(version, encoding, error_correction) + (getEncodingBitCount(version, encoding) + getEncodingModeIndicator() + 7) / 8]u8 {
    const encoding_mode_indicator: u4 = @intFromEnum(EncodingMode.byte);
    // FIX SUPPORT OTHER ENCODINGS AND VERSIONS THAN VERSION 1 - 9 FOR BYTE
    const encoding_bit_count = getEncodingBitCount(version, encoding);
    const mode_indicator_bit_length = getEncodingModeIndicator();

    // String plus encoding header
    const data_length = string.len + (mode_indicator_bit_length + encoding_bit_count + 7) / 8;

    const code_word_capacity = comptime lookupDataCodewordCapacity(version, encoding, error_correction) + (encoding_bit_count + mode_indicator_bit_length + 7) / 8;

    const bits_left = (code_word_capacity - data_length) * 8;

    // FIX: plus because encoding_bit_count and mode_indicator_bit_length need to fit along side the data, plus seven to round up
    var data_buffer: [code_word_capacity]u8 = .{0} ** (code_word_capacity);

    // idea for faster or more idiomatic way to write bits to buffer
    var buffer_stream = std.io.fixedBufferStream(&data_buffer);
    var bit_writer = std.io.bitWriter(.big, buffer_stream.writer());

    try bit_writer.writeBits(encoding_mode_indicator, 4);
    try bit_writer.writeBits(string.len, 8);

    const written_string = try bit_writer.write(string);
    if (written_string != string.len) return error.CantWriteString;

    // Terminator bits
    // FIX SO THAT I GUARANTEE NO BUFFER OVERFLOW
    if (bits_left > 0) try bit_writer.writeBits(@as(u4, 0), @min(bits_left, 4));

    // Align to byte
    if (bit_writer.bit_count != 0) try bit_writer.writeBits(@as(u8, 0), bit_writer.bit_count);

    // Padding codewords
    for (0..code_word_capacity - data_length, 0..) |_, i| {
        if (i % 2 == 0) {
            try bit_writer.writeBits(@as(u8, 0b11101100), 8);
        } else {
            try bit_writer.writeBits(@as(u8, 0b00010001), 8);
        }
    }

    return data_buffer;
}

fn computeRemainder(data: []const u8, generator: []const u8, degree: u8) [MAX_DEGREE]u8 {
    var result: [MAX_DEGREE]u8 = .{0} ** MAX_DEGREE;
    for (0..data.len) |i| {
        const factor: u8 = data[i] ^ result[0];
        std.mem.copyBackwards(u8, result[0 .. degree - 1], result[1..degree]);
        result[degree - 1] = 0;
        for (0..degree) |j| result[j] ^= mulGF256(generator[j], factor);
    }
    return result;
}

// FIX ADD SUPPORT FOR HIGHER VERSIONS WITH MULTIPLE ERROR CORRECTION BLOCKS
fn generateErrorCodewords(messagePolynomial: []const u8, generatorPolynomial: []const u8) ![26]u8 {
    const GFConvert = struct {
        fn itoa(x: u8) ?u8 {
            for (exp, 0..) |exp_val, index| if (exp_val == x) return @intCast(index);
            return null;
        }

        fn atoi(x: ?u8) u8 {
            return if (x) |val| exp[val] else 0;
        }
    };

    var mp = try std.BoundedArray(?u8, 255).init(0);

    for (messagePolynomial) |x| try mp.append(GFConvert.itoa(x));
    try mp.appendNTimes(null, 26);

    for (0..messagePolynomial.len) |i| {
        const lead = mp.get(i);
        for (generatorPolynomial, 0..) |x, j| {
            var y = GFConvert.atoi(@as(u8, @intCast((@as(usize, @intCast(x)) + @as(usize, @intCast(lead orelse 0))) % 255)));
            if (mp.get(i + j) != null) y ^= GFConvert.atoi(mp.get(i + j));
            mp.set(i + j, if (y == 0) null else GFConvert.itoa(y));
        }
    }
    std.debug.print("\n", .{});

    var result: [26]u8 = undefined;
    for (mp.slice()[messagePolynomial.len..], 0..) |x, i| result[i] = if (x == null) 0 else GFConvert.atoi(x);

    return result;
}

pub fn main() !void {
    const string = "Hello, world!Hello, world!Hello, world!";
    var code = Code{ .ecl = .M, .version = 3 };
    generateTimingPattern(&code);
    generateAllFinderPatterns(&code);
    generateAllAlignmentPatterns(&code);
    generateDarkBit(&code);
    generateFormatInfo(&code);
    const encoded_data = try getEncodedData(string, 3, EncodingMode.byte, .M);
    const error_correction_codewords = try generateErrorCodewords(&encoded_data, &getGeneratorPolynomial(26));
    std.debug.print("error codewords: {any}\n", .{error_correction_codewords});
    printCode(&code);
}
