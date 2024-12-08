const std = @import("std");
const assert = std.debug.assert;

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

const ECL = enum(u2) {
    L = 0b01,
    M = 0b00,
    Q = 0b11,
    H = 0b10,
};

pub const Code = struct {
    version: u8,
    modules: [177][177]bool = .{.{false} ** 177} ** 177,
    ecl: ECL,

    fn getSize(self: *Code) usize {
        return (self.version * 4) + 17;
    }
};

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

pub fn main() !void {
    var code = try generateTextCode("hello, world!");
    generateTimingPattern(&code);
    generateAllFinderPatterns(&code);
    generateAllAlignmentPatterns(&code);
    generateDarkBit(&code);
    generateFormatInfo(&code);
    printCode(&code);
}
