const std = @import("std");
const mem = std.mem;

pub const Headers = std.StringHashMap([]const u8);

/// Represents a HTTP request
pub const HTTPRequest = struct {
    //allocator: *mem.Allocator,
    headers: Headers,
    verb: []const u8,
    path: []const u8,
    body: []const u8,

    pub fn deinit(self: *@This()) void {
        self.headers.deinit();
    }

    pub fn parseAndFill(allocator: *mem.Allocator, data: []const u8) !@This() {
        var headers = Headers.init(allocator);

        var lines_it = mem.separate(data, "\r\n");

        var body_offset: usize = 0;

        var first_line = lines_it.next().?;
        var first_it = mem.separate(first_line, " ");
        const verb = first_it.next() orelse return error.NotEnoughData;
        const path = first_it.next().?;
        const http = first_it.next().?;
        body_offset += verb.len + path.len + http.len + 2;
        std.debug.warn("verb='{}' path='{}' version='{}'\n", verb, path, http);

        while (lines_it.next()) |header_line| {
            if (header_line.len == 0) break;
            var header_it = mem.separate(header_line, ": ");

            var header_name = header_it.next().?;
            var header_value = header_it.next().?;
            body_offset += header_name.len + 2 + header_value.len + 2;

            _ = try headers.put(header_name, header_value);

            std.debug.warn("header name='{}', value='{}'\n", header_name, header_value);
        }

        var body = data[body_offset + 2 .. data.len - 2];

        return @as(@This(), .{
            .headers = headers,
            .verb = verb,
            .path = path,
            .body = body,
        });
    }
};
