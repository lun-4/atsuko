const std = @import("std");
const http = @import("http.zig");

const os = std.os;

pub fn main() anyerror!void {
    const allocator = std.heap.direct_allocator;
    var addr = try std.net.Address.parseIp4("0.0.0.0", 8000);
    var server = std.net.StreamServer.init(.{});
    defer server.deinit();

    std.debug.warn("hosting at localhost:8000\n");

    const nonblock = if (std.io.is_async) os.SOCK_NONBLOCK else 0;
    const sock_flags = os.SOCK_STREAM | os.SOCK_CLOEXEC | nonblock;
    const proto = if (addr.any.family == os.AF_UNIX) @as(u32, 0) else os.IPPROTO_TCP;

    const sockfd = try os.socket(addr.any.family, sock_flags, proto);
    server.sockfd = sockfd;
    errdefer {
        os.close(sockfd);
        server.sockfd = null;
    }

    // TODO fix this?
    var optval: c_int = 1;
    var rc = std.os.linux.setsockopt(
        server.sockfd.?,
        os.linux.SOL_SOCKET,
        os.linux.SO_REUSEADDR,
        @ptrCast([*]const u8, &optval),
        @sizeOf(c_int),
    );
    var errno = std.os.linux.getErrno(rc);
    std.debug.warn("setsockopt: {}, errno={}\n", rc, errno);

    var socklen = addr.getOsSockLen();
    try os.bind(sockfd, &addr.any, socklen);
    try os.listen(sockfd, server.kernel_backlog);
    try os.getsockname(sockfd, &server.listen_address.any, &socklen);

    switch (errno) {
        0 => {},
        std.os.EBADF => return error.InvalidSocket,
        std.os.EDOM => return error.TimeoutTooBig,
        std.os.EINVAL => return error.InvalidOption,
        std.os.EISCONN => return error.AlreadyConnected,
        //std.os.ENOPROTOOOPT => return error.InvalidProtocolOption,
        std.os.ENOTSOCK => return error.NotSocket,

        std.os.ENOMEM => return error.OutOfMemory,
        std.os.ENOBUFS => return error.InsufficientResources,

        else => return std.os.unexpectedErrno(errno),
    }

    while (true) {
        var sock = try server.accept();
        defer sock.close();

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
