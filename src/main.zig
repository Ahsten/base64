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

pub fn main() !void {
    const base = Base64.init();
    std.debug.print("Charater at 28: {c}\n", .{base.char_at(28)});
}

// Tests
const expect = std.testing.expect;

test "char_at method" {
    const base = Base64.init();
    try expect(base.char_at(3) == 'D');
}
