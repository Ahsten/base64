const std = @import("std");

const Base64 = struct {
    table: *const [64]u8,

    pub fn init() Base64 {
        const upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        const lower = "abcdefghijklmnopqrstuvwxyz";
        const numbers = "0123456789+/";
        return Base64{ .table = upper ++ lower ++ numbers };
    }

    pub fn char_at(self: Base64, index: u8) u8 {
        return self.table[index];
    }
};

fn calc_encode_length(input: []const u8) !usize {
    if (input.len < 3) {
        return 4;
    }

    const n_groups: usize = try std.math.divCeil(usize, input.len, 3);
    return n_groups * 4;
}

fn calc_decode_length(input: []const u8) !usize {
    if (input.len < 4) {
        return 3;
    }

    const n_groups: usize = try std.math.divFloor(usize, input.len, 4);
    var multiple_groups: usize = n_groups * 3;
    var i: usize = input.len - 1;
    while (i > 0) : (i -= 1) {
        if (input[i] == '=') {
            multiple_groups -= 1;
        } else {
            break;
        }
    }
    return multiple_groups;
}

pub fn main() !void {
    const base = Base64.init();
    std.debug.print("Charater at 28: {c}\n", .{base.char_at(28)});
}

// Tests
const testing = std.testing;

test "char_at method" {
    const base = Base64.init();
    try testing.expect(base.char_at(3) == 'D');
}

test "calc_encode_length less than 3" {
    try testing.expectEqual(calc_encode_length("Hi"), 4);
}

test "calc_encode_length greater than 4" {
    try testing.expectEqual(calc_encode_length("Hello"), 8);
}

test "calc_decode_length less than 4" {
    try testing.expectEqual(calc_decode_length("Hi"), 3);
}

test "calc_decode_length greater than 4" {
    try testing.expectEqual(calc_decode_length("SGk="), 2);
}
