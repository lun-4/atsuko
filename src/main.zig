const std = @import("std");
const http = @import("http.zig");

const os = std.os;

pub fn main() anyerror!void {
    const allocator = std.heap.direct_allocator;
    var addr = try std.net.Address.parseIp4("0.0.0.0", 8000);

    var server = std.net.StreamServer.init(.{ .reuse_address = true });
    defer server.deinit();

    std.debug.warn("hosting at localhost:8000\n");

    try server.listen(addr);

    while (true) {
        var conn = try server.accept();
        defer conn.file.close();
        var sock = conn.file;

        var buf = try allocator.alloc(u8, 128);
        const bytecount = try sock.read(buf);
        var msg = buf[0..bytecount];

        var request = try http.HTTPRequest.parseAndFill(allocator, msg);
        defer request.deinit();
        std.debug.warn("got verb={}, path={}, body (len {})={}\n", request.verb, request.path, request.body.len, request.body);

        var stream = &sock.outStream().stream;
        var response = http.HTTPResponse.init(allocator);
        defer response.deinit();
        response.status_code = 204;

        try response.write(stream);
    }
}
