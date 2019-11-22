const std = @import("std");
const mem = std.mem;

/// Represents a HTTP request
pub const HTTPRequest = struct {
    allocator: *mem.Allocator,

    pub fn init(allocator: *mem.Allocator) @This() {
        return .{ .allocator = allocator };
    }

    pub fn parseAndFill(self: *@This(), data: []const u8) !void {
        var lines_it = mem.separate(data, "\r\n");
        var idx: usize = 0;

        var is_body: bool = false;

        while (lines_it.next()) |line| {
            if (idx == 0) {
                // first line, get verb, path, and HTTP/1.1
                var first_it = mem.separate(line, " ");
                const verb = first_it.next() orelse return error.NotEnoughData;
                const path = first_it.next().?;
                const http = first_it.next().?;
                std.debug.warn("verb='{}' path='{}' version='{}'\n", verb, path, http);
            }

            idx += 1;
        }
    }
};
