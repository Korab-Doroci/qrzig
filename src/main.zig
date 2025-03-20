const std = @import("std");
const types = @import("types.zig");

// Code
const Code = types.Code;
const EncodingMode = types.EncodingMode;
const ErrorCorrectionLevel = types.ErrorCorrectionLevel;
const error_correction_codewords_per_block = types.error_correction_codewords_per_block;
const DataCodewordCapacityTable = types.DataCodewordCapacityTable;

// Error correction
const mulGF256 = types.mulGF256;
const addGF256 = types.addGF256;
const getDivisor = types.getDivisor;
const polyMulGF256 = types.polyMulGF256;
const polyDivGF256 = types.polyDivGF256;
const getGeneratorPolynomial = types.getGeneratorPolynomial;
const coefficient_table = types.coefficient_table;
const version_info_strings = types.version_info_strings;
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

fn getFormatInfo(code: *Code) u15 {
    // FIX SUPPORT ALL MASKS
    const mask_pattern: u3 = 0b1; // You might want to make this dynamic based on your mask selection
    return types.format_strings[@as(usize, code.ecl.getOffset()) * 8 + @as(usize, mask_pattern)].bits;
}

fn getVersionInfo(code: *Code) u18 {
    return version_info_strings[code.version - 7];
}

fn generateFormatInfo(code: *Code) void {
    const size = code.getSize();
    const format_info = getFormatInfo(code);

    for (0..15) |i| {
        const bit = (format_info & (@as(u15, 1) << @intCast(14 - i))) != 0;

        // Top-left finder pattern
        if (i < 8) {
            const x_offset = if (i > 5) i + 1 else i;
            code.modules[8][x_offset] = bit;
        } else {
            const y_offset = if (i < 9) 15 - i else 14 - i;
            code.modules[y_offset][8] = bit;
        }

        // Bottom-left and top-right finder patterns
        if (i < 7) {
            code.modules[size - 1 - i][8] = bit;
        } else {
            code.modules[8][size - 15 + i] = bit;
        }
    }

    // For version 7 and above, add version information
    if (code.version >= 7) {
        const version_info = getVersionInfo(code);

        // Place version info below bottom-right finder pattern
        for (0..6) |i| {
            for (0..3) |j| {
                const bit = (version_info & (@as(u18, 1) << @intCast(17 - (i * 3 + j)))) != 0;
                code.modules[size - 11 + j][i] = bit;
                code.modules[i][size - 11 + j] = bit;
            }
        }
    }
}

fn applyFormatAndVersionInfo(code: *Code) void {
    const size = code.getSize();
    const mask: u3 = 0b1; // You might want to make this dynamic based on your mask selection
    const format_info = getFormatInfo(code.ecl, mask);

    for (0..15) |i| {
        const bit = (format_info & (@as(u15, 1) << @intCast(14 - i))) != 0;

        // Top-left finder pattern
        if (i < 8) {
            const x_offset = if (i >= 6) i + 1 else i;
            code.modules[8][x_offset] = bit;
        } else {
            const y_offset = if (i < 9) 8 - (i - 7) else 8 - (i - 6);
            code.modules[y_offset][8] = bit;
        }

        // Bottom-left and top-right finder patterns
        if (i < 7) {
            code.modules[size - 1 - i][8] = bit;
        } else {
            code.modules[8][size - 15 + i] = bit;
        }
    }

    // Always set the dark module
    generateDarkBit(code);

    // For version 7 and above, add version information
    if (code.version >= 7) {
        const version_info = getVersionInfo(code);

        // Place version info below bottom-right finder pattern
        for (0..6) |i| {
            for (0..3) |j| {
                const bit = (version_info & (@as(u18, 1) << @intCast(17 - (i * 3 + j)))) != 0;
                code.modules[size - 11 + j][i] = bit;
                code.modules[i][size - 11 + j] = bit;
            }
        }
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

fn getMinimumVersion(
    comptime length: usize,
    comptime encoding: EncodingMode,
    comptime error_correction: ErrorCorrectionLevel,
) comptime_int {
    comptime {
        var version: u8 = 1;
        while (version <= 40) {
            const encoding_bit_count = getEncodingBitCount(version, encoding);
            const mode_indicator_bit_length = getEncodingModeIndicator();
            const total_bits_needed = mode_indicator_bit_length + encoding_bit_count + (length * 8);
            const capacity = lookupDataCodewordCapacity(version, encoding, error_correction) * 8;

            if (capacity >= total_bits_needed) {
                return version;
            }
            version += 1;
        }
        @compileError("String too long for any QR code version");
    }
}

fn getEncodedData(
    comptime string: []const u8,
    comptime version: u8,
    comptime encoding: EncodingMode,
    comptime error_correction: ErrorCorrectionLevel,
) ![lookupDataCodewordCapacity(version, encoding, error_correction) + (getEncodingBitCount(version, encoding) + getEncodingModeIndicator() + 7) / 8]u8 {
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

// // FIX ADD SUPPORT FOR HIGHER VERSIONS WITH MULTIPLE ERROR CORRECTION BLOCKS
// fn generateErrorCodewords(messagePolynomial: []const u8, generatorPolynomial: []const u8) ![26]u8 {
//     const GFConvert = struct {
//         fn itoa(x: u8) ?u8 {
//             for (exp, 0..) |exp_val, index| if (exp_val == x) return @intCast(index);
//             return null;
//         }
//
//         fn atoi(x: ?u8) u8 {
//             return if (x) |val| exp[val] else 0;
//         }
//     };
//
//     var mp = try std.BoundedArray(?u8, 255).init(0);
//
//     for (messagePolynomial) |x| try mp.append(GFConvert.itoa(x));
//     try mp.appendNTimes(null, 26);
//
//     for (0..messagePolynomial.len) |i| {
//         const lead = mp.get(i);
//         for (generatorPolynomial, 0..) |x, j| {
//             var y = GFConvert.atoi(@as(u8, @intCast((@as(usize, @intCast(x)) + @as(usize, @intCast(lead orelse 0))) % 255)));
//             if (mp.get(i + j) != null) y ^= GFConvert.atoi(mp.get(i + j));
//             mp.set(i + j, if (y == 0) null else GFConvert.itoa(y));
//         }
//     }
//     std.debug.print("\n", .{});
//
//     var result: [26]u8 = undefined;
//     for (mp.slice()[messagePolynomial.len..], 0..) |x, i| result[i] = if (x == null) 0 else GFConvert.atoi(x);
//
//     return result;
// }

fn generateErrorCodewords(messagePolynomial: []const u8, generatorPolynomial: []const u8) !std.BoundedArray(u8, MAX_DEGREE) {
    const GFConvert = struct {
        fn itoa(x: u8) ?u8 {
            for (exp, 0..) |exp_val, index| {
                if (exp_val == x) return @intCast(index);
            }
            return null;
        }

        fn atoi(x: ?u8) u8 {
            return if (x) |val| exp[val] else 0;
        }
    };

    const ec_count = generatorPolynomial.len - 1;
    var mp = try std.BoundedArray(?u8, 255).init(0);

    // Convert message polynomial to exponents (logarithms)
    for (messagePolynomial) |x| {
        try mp.append(GFConvert.itoa(x));
    }
    // Append space for EC codewords (initialized to zero/null)
    try mp.appendNTimes(null, ec_count);

    // Perform polynomial division
    for (0..messagePolynomial.len) |i| {
        const lead = mp.get(i);
        if (lead == null) continue; // Skip if leading coefficient is zero

        for (generatorPolynomial, 0..) |x, j| {
            const exponent_sum = (@as(usize, x) + lead.?) % 255;
            const exponent = @as(u8, @intCast(exponent_sum));
            var y = exp[exponent];

            // XOR with current value if present
            if (mp.get(i + j)) |current| {
                const current_val = exp[current];
                y ^= current_val;
            }

            // Store result back as exponent (or null for zero)
            mp.set(i + j, GFConvert.itoa(y));
        }
    }

    // Extract EC codewords from the remainder
    var result = try std.BoundedArray(u8, MAX_DEGREE).init(0);
    const ec_start = messagePolynomial.len;
    const ec_end = ec_start + ec_count;
    for (mp.slice()[ec_start..ec_end]) |x| {
        try result.append(GFConvert.atoi(x));
    }

    return result;
}

fn applyModules(code: *Code, codewords: []u8) void {
    const size = code.getSize();
    var codeword_index: usize = 0;
    var bit_index: u3 = 7;
    var x: usize = size - 1; // Start at bottom-right
    var going_up: bool = true;

    while (x >= 0) {
        if (x == 6) x -= 1;

        // Process two columns (x and x-1 if valid)
        const right_col = x;
        const left_col = if (x > 0) x - 1 else right_col;

        var y: usize = if (going_up) size - 1 else 0;

        while ((going_up and y >= 0) or (!going_up and y < size)) {
            // Process right column
            if (right_col < size and !isReservedModule(code, right_col, y)) {
                if (codeword_index < codewords.len) {
                    const bit = (codewords[codeword_index] >> bit_index) & 1;
                    code.modules[y][right_col] = bit != 0;
                    if (bit_index == 0) {
                        codeword_index += 1;
                        bit_index = 7;
                    } else {
                        bit_index -= 1;
                    }
                }
            }

            // Process left column (if different)
            if (left_col != right_col and left_col < size and !isReservedModule(code, left_col, y)) {
                if (codeword_index < codewords.len) {
                    const bit = (codewords[codeword_index] >> bit_index) & 1;
                    code.modules[y][left_col] = bit != 0;
                    if (bit_index == 0) {
                        codeword_index += 1;
                        bit_index = 7;
                    } else {
                        bit_index -= 1;
                    }
                }
            }

            if (going_up and y == 0) break else if (going_up) y -= 1 else y += 1;
        }

        // Move to next column pair
        if (x < 2) break;
        x -= 2;
        going_up = !going_up;

        // Stop if we've used all codewords
        if (codeword_index >= codewords.len) break;
    }
}

fn isReservedModule(code: *Code, x: usize, y: usize) bool {
    const size = code.getSize();
    const version = code.version;

    // Validate coordinates are within the QR code
    if (x >= size or y >= size) {
        return false;
    }

    // Check finder patterns (top-left, top-right, bottom-left) and their separators
    // Top-left finder pattern (and separator)
    if (x < 9 and y < 9) {
        return true;
    }

    // Top-right finder pattern (and separator)
    if (x >= size - 8 and y < 9) {
        return true;
    }

    // Bottom-left finder pattern (and separator)
    if (x < 9 and y >= size - 8) {
        return true;
    }

    // Timing patterns
    // Horizontal timing pattern
    if (y == 6) {
        return true;
    }

    // Vertical timing pattern
    if (x == 6) {
        return true;
    }

    // Alignment patterns (for version 2 and higher)
    if (version >= 2) {
        // Get alignment pattern positions
        const positions = getAlignmentPatternPositions(version);

        // Check if the current position is within any alignment pattern
        for (positions) |pos_x| {
            for (positions) |pos_y| {
                // Skip if it overlaps with finder patterns
                if ((pos_x < 10 and pos_y < 10) or
                    (pos_x < 10 and pos_y >= size - 10) or
                    (pos_x >= size - 10 and pos_y < 10))
                {
                    continue;
                }

                // Check if within the 5x5 alignment pattern
                if (x >= pos_x - 2 and x <= pos_x + 2 and
                    y >= pos_y - 2 and y <= pos_y + 2)
                {
                    return true;
                }
            }
        }
    }

    // Version information (for versions 7 and higher)
    if (version >= 7) {
        // Top-right version information
        if (x >= size - 11 and x < size - 8 and y < 6) {
            return true;
        }

        // Bottom-left version information
        if (y >= size - 11 and y < size - 8 and x < 6) {
            return true;
        }
    }

    // Format information around the finder patterns
    // Top-left format information
    if ((y == 8 and x < 9) or (x == 8 and y < 9 and y != 6)) {
        return true;
    }

    // Top-right and bottom-left format information
    if ((y == 8 and x >= size - 8) or (x == 8 and y >= size - 8)) {
        return true;
    }

    // Dark module (always at this specific location)
    if (x == 8 and y == size - 8) {
        return true;
    }

    return false;
}

fn applyMaskPattern(code: *Code, maskPattern: u3) void {
    const size = code.getSize();
    for (0..size) |y| {
        for (0..size) |x| {
            if (!isReservedModule(code, x, y) and shouldInvert(maskPattern, x, y)) {
                code.modules[y][x] = !code.modules[y][x]; // Fixed indices
            }
        }
    }
}

fn shouldInvert(maskPattern: u3, x: usize, y: usize) bool {
    return switch (maskPattern) {
        0 => (x + y) % 2 == 0,
        1 => y % 2 == 0,
        2 => x % 3 == 0,
        3 => (x + y) % 3 == 0,
        4 => (y / 2 + x / 3) % 2 == 0,
        5 => ((x * y) % 2) + ((x * y) % 3) == 0,
        6 => (((x * y) % 2) + ((x * y) % 3)) % 2 == 0,
        7 => (((x + y) % 2) + ((x * y) % 3)) % 2 == 0,
    };
}

fn generateErrorCodewordsForBlocks(
    data: []const u8,
    comptime version: u8,
    comptime encoding: EncodingMode,
    comptime ecl: ErrorCorrectionLevel,
) ![]u8 {
    const ecl_idx = ecl.getOffset();
    const enc_idx = encoding.getOffset();

    const v = version - 1;
    const total_data_codewords = DataCodewordCapacityTable[v][ecl_idx * 4 + enc_idx].capacity;
    const header_bits = getEncodingBitCount(version, encoding) + getEncodingModeIndicator();
    const header_bytes = (header_bits + 7) / 8;
    // const total_data_bytes = total_data_codewords + header_bytes;

    // if (data.len != total_data_bytes) {
    //     @compileError("Data length doesn't match expected capacity");
    // }

    const num_blocks = num_error_correction_blocks[ecl_idx][v];
    const ec_per_block = error_correction_codewords_per_block[ecl_idx][v];
    const remainder_blocks = total_data_codewords % num_blocks;
    const base_data_per_block = total_data_codewords / num_blocks;
    const total_ec_codewords = num_blocks * ec_per_block;
    const total_codewords = total_data_codewords + total_ec_codewords;

    // Split data into blocks
    var blocks: [40][]const u8 = undefined;
    var data_pos: usize = 0;
    for (0..num_blocks) |i| {
        const block_size = base_data_per_block + (if (i < remainder_blocks) 1 else 0);
        blocks[i] = data[data_pos .. data_pos + block_size];
        data_pos += block_size;
    }

    // Generate error correction for each block
    var result: [total_codewords + header_bytes]u8 = undefined;
    var result_pos: usize = 0;
    std.mem.copyForwards(u8, result[0..data.len], data);
    result_pos = data.len;

    for (0..num_blocks) |i| {
        const generator = getGeneratorPolynomial(ec_per_block);
        const block_data = blocks[i];
        var remainder = computeRemainder(block_data, &generator, ec_per_block);
        std.mem.copyForwards(u8, result[result_pos .. result_pos + ec_per_block], remainder[0..ec_per_block]);
        result_pos += ec_per_block;
    }

    return result[0 .. total_codewords + header_bytes];
}

fn interleaveCodewords(
    codewords: []const u8,
    comptime version: u8,
    comptime encoding: EncodingMode,
    comptime ecl: ErrorCorrectionLevel,
) []u8 {
    const ecl_idx = ecl.getOffset();
    const enc_idx = encoding.getOffset();
    const v = version - 1;
    const total_data_codewords = DataCodewordCapacityTable[v][ecl_idx * 4 + enc_idx].capacity;
    const header_bytes = (getEncodingBitCount(version, encoding) + getEncodingModeIndicator() + 7) / 8;
    const num_blocks = num_error_correction_blocks[ecl_idx][v];
    const ec_per_block = error_correction_codewords_per_block[ecl_idx][v];
    const remainder_blocks = total_data_codewords % num_blocks;
    const base_data_per_block = total_data_codewords / num_blocks;

    // Split data into blocks
    var blocks: [40][]const u8 = undefined;
    var data_pos: usize = 0;
    for (0..num_blocks) |i| {
        const block_size = base_data_per_block + (if (i < remainder_blocks) 1 else 0);
        blocks[i] = codewords[data_pos .. data_pos + block_size];
        data_pos += block_size;
    }

    var ec_start = total_data_codewords + header_bytes;
    var ec_blocks: [40][]const u8 = undefined;
    for (0..num_blocks) |i| {
        ec_blocks[i] = codewords[ec_start .. ec_start + ec_per_block];
        ec_start += ec_per_block;
    }

    // Interleave
    var result: [codewords.len]u8 = undefined;
    var pos: usize = 0;

    // Interleave data codewords
    const max_data_len = base_data_per_block + 1;
    for (0..max_data_len) |i| {
        for (0..num_blocks) |b| {
            if (i < blocks[b].len) {
                result[pos] = blocks[b][i];
                pos += 1;
            }
        }
    }

    // Interleave EC codewords
    for (0..ec_per_block) |i| {
        for (0..num_blocks) |b| {
            result[pos] = ec_blocks[b][i];
            pos += 1;
        }
    }

    return result;
}

pub fn main() !void {
    const string = "Hello, world!Hello, world!Hello, world!Hello, world!Hello, world!Hello, world!";
    const code_version = getMinimumVersion(string.len, .byte, .M);
    var code = Code{ .ecl = .M, .version = code_version };
    generateTimingPattern(&code);
    generateAllFinderPatterns(&code);
    generateAllAlignmentPatterns(&code);
    generateFormatInfo(&code);
    generateDarkBit(&code);

    const encoded_data = try getEncodedData(string, code_version, EncodingMode.byte, .M);
    const error_correction_codewords = try generateErrorCodewords(&encoded_data, &getGeneratorPolynomial(26));
    // const final_codewords = try generateErrorCodewordsForBlocks(&encoded_data, code_version, .byte, .M);
    // const interleaved = interleaveCodewords(final_codewords, code_version, .byte, .M);
    // for (encoded_data ++ error_correction_codewords) |codeword| {
    //     std.debug.print("{x} ", .{codeword});
    // }
    std.debug.print("\n\n", .{});
    // _ = error_correction_codewords;
    // var onezero: [70]u8 = .{170} ** 70;
    // applyModules4(&code)j
    // applyModules(&code, &onezero);
    applyModules(&code, &encoded_data ++ error_correction_codewords.buffer);
    applyMaskPattern(&code, 0b1);
    // applyModules(&code, &onezero);
    printCode(&code);
}
