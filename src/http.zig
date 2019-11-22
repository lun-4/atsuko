const std = @import("std");
const mem = std.mem;

pub const Headers = std.StringHashMap([]const u8);

/// Represents a HTTP request
pub const HTTPRequest = struct {
    //allocator: *mem.Allocator,
    headers: Headers,
    verb: []const u8,
    path: []const u8,

    pub fn deinit(self: *@This()) void {
        self.headers.deinit();
    }

    pub fn parseAndFill(allocator: *mem.Allocator, data: []const u8) !@This() {
        var headers = Headers.init(allocator);

        var lines_it = mem.separate(data, "\r\n");

        var first_line = lines_it.next().?;
        var first_it = mem.separate(first_line, " ");
        const verb = first_it.next() orelse return error.NotEnoughData;
        const path = first_it.next().?;
        const http = first_it.next().?;
        std.debug.warn("verb='{}' path='{}' version='{}'\n", verb, path, http);

        while (lines_it.next()) |header_line| {
            if (header_line.len == 0) break;
            var header_it = mem.separate(header_line, ": ");

            var header_name = header_it.next().?;
            var header_value = header_it.next().?;

            _ = try headers.put(header_name, header_value);

            std.debug.warn("header name='{}', value='{}'\n", header_name, header_value);
        }

        while (lines_it.next()) |body_line| {
            // TODO
            std.debug.warn("body line: {}\n", body_line);
        }

        return @as(@This(), .{
            .headers = headers,
            .verb = verb,
            .path = path,
        });
    }
};
