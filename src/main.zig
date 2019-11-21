const std = @import("std");

pub fn main() anyerror!void {
    var addr = try std.net.Address.parseIp4("0.0.0.0", 8000);
    var server = std.net.StreamServer.init(.{});
    defer server.deinit();

    try server.listen(addr);

    while (true) {
        var sock = try server.accept();
        defer sock.close();

        std.debug.warn("awoo bitch {}\n", sock.handle);

        var buf = try std.heap.direct_allocator.alloc(u8, 128);
        const bytecount = try sock.read(buf);
        var msg = buf[0..bytecount];

        std.debug.warn("got '{}'\n", msg);
    }
}
