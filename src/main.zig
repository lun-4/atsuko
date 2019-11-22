const std = @import("std");
const http = @import("http.zig");

const os = std.os;

pub fn main() anyerror!void {
    const allocator = std.heap.direct_allocator;
    var addr = try std.net.Address.parseIp4("0.0.0.0", 8000);
    var server = std.net.StreamServer.init(.{});
    defer server.deinit();

    try server.listen(addr);

    std.debug.warn("hosting at localhost:8000\n");

    // TODO fix this?
    var optval = [_]u8{1};
    _ = std.os.linux.setsockopt(server.sockfd.?, os.linux.SOL_SOCKET, os.linux.SO_REUSEADDR, &optval, 1);

    while (true) {
        var sock = try server.accept();
        defer sock.close();

        var buf = try allocator.alloc(u8, 128);
        const bytecount = try sock.read(buf);
        var msg = buf[0..bytecount];

        var request = http.HTTPRequest.init(allocator);
        try request.parseAndFill(msg);
    }
}
