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

    pub fn char_index(self: Base64, char: u8) u8 {
        if (char == '=') {
            return 64;
        }

        var index: u8 = 0;
        for (0..63) |_| {
            if (self.char_at(index) == char) {
                break;
            }
            index += 1;
        }
        return index;
    }

    pub fn encode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return "";
        }

        const length = try calc_encode_length(input);
        var output = try allocator.alloc(u8, length);
        var buffer = [3]u8{ 0, 0, 0 };
        var count: u8 = 0;
        var iout: u64 = 0;

        for (input, 0..) |_, i| {
            buffer[count] = input[i];
            count += 1;
            if (count == 3) {
                output[iout] = self.char_at(buffer[0] >> 2);
                output[iout + 1] = self.char_at(((buffer[0] & 0x03) << 4) + (buffer[1] >> 4));
                output[iout + 2] = self.char_at((buffer[1] & 0x0f) + (buffer[2] >> 6));
                output[iout + 3] = self.char_at(buffer[2] & 0x3f);
                iout += 4;
                count = 0;
            }
        }

        if (count == 1) {
            output[iout] = self.char_at(buffer[0] >> 2);
            output[iout + 1] = self.char_at((buffer[0] & 0x03) << 4);
            output[iout + 2] = '=';
            output[iout + 3] = '=';
        }

        if (count == 2) {
            output[iout] = self.char_at(buffer[0] >> 2);
            output[iout + 1] = self.char_at(((buffer[0] & 0x03) << 4) + (buffer[1] >> 4));
            output[iout + 2] = self.char_at(((buffer[1] & 0x0f) << 2));
            output[iout + 3] = '=';
            iout += 4;
        }

        return output;
    }

    pub fn decode(self: Base64, allocator: std.mem.Allocator, input: []const u8) ![]u8 {
        if (input.len == 0) {
            return "";
        }

        const size = try calc_decode_length(input);
        var output = try allocator.alloc(u8, size);
        var count: u8 = 0;
        var iout: u64 = 0;
        var buffer = [4]u8{ 0, 0, 0, 0 };

        for (0..output.len) |i| {
            output[i] = 0;
        }

        for (0..input.len) |i| {
            buffer[count] = self.char_index(input[i]);
            count += 1;

            if (count == 4) {
                output[iout] = (buffer[0] << 2) + (buffer[1] >> 4);
                if (buffer[2] != 64) {
                    output[iout + 1] = (buffer[1] << 4) + (buffer[2] >> 2);
                }
                if (buffer[3] != 64) {
                    output[iout + 2] = (buffer[2] << 6) + buffer[3];
                }
                iout += 3;
                count = 0;
            }
        }

        return output;
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
    const stdout = std.io.getStdOut().writer();
    var memory_buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const allocator = fba.allocator();

    const text = "Testing some more stuff";
    const base64_text = "VGVzdGluZyBzb21lIG1vcmUgc3R1ZmY=";
    const base64 = Base64.init();
    const encoded_text = try base64.encode(allocator, text);
    const decoded_text = try base64.decode(allocator, base64_text);
    try stdout.print("Encoded text: {s}\n", .{encoded_text});
    try stdout.print("Decoded text: {s}\n", .{decoded_text});
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

test "endcode" {
    const base = Base64.init();
    var memory_buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&memory_buffer);
    const text = try base.encode(fba.allocator(), "Hi");
    try testing.expectEqualStrings("SGk=", text);
}
