///! Platform host that serves HTML returned by the Roc application.
const std = @import("std");
const builtin = @import("builtin");
const httpz = @import("httpz");
const abi = @import("roc_platform_abi.zig");

pub const std_options: std.Options = .{
    .allow_stack_tracing = false,
};

/// Private RocHost used by exported runtime symbols and the page handler.
var g_roc_host: ?*abi.RocHost = null;

// OS-specific entry point handling (not exported during tests)
comptime {
    if (!builtin.is_test) {
        // Export main for all platforms
        @export(&main, .{ .name = "main" });

        // Windows MinGW/MSVCRT compatibility: export __main stub
        if (@import("builtin").os.tag == .windows) {
            @export(&__main, .{ .name = "__main" });
        }
    }
}

// Windows MinGW/MSVCRT compatibility stub
// The C runtime on Windows calls __main from main for constructor initialization
fn __main() callconv(.c) void {}

// C compatible main for runtime
fn main(argc: c_int, argv: [*][*:0]u8) callconv(.c) c_int {
    return platform_main(@intCast(argc), argv);
}

extern fn getauxval(kind: usize) usize;

// Roc's musl CRT starts this executable instead of Zig's normal entrypoint.
// Initialize Zig's TLS metadata from the ELF program headers before httpz
// creates worker threads; otherwise std.Thread.spawn sees uninitialized TLS.
// TLS (thread-local storage) gives every thread its own runtime state. ELF is
// the Linux executable format; its program headers describe the TLS layout.
fn initZigTls() void {
    // TLS setup is required only on Linux, where this platform uses musl.
    if (comptime builtin.os.tag == .linux) {
        // AT_PHDR points to the executable's ELF program-header table.
        const phdrs: [*]std.elf.Phdr = @ptrFromInt(getauxval(std.elf.AT_PHDR));
        // AT_PHNUM gives the number of entries in that table.
        const phdr_count = getauxval(std.elf.AT_PHNUM);
        // Zig reads the PT_TLS header to initialize its thread-local storage.
        std.os.linux.tls.initStatic(phdrs[0..phdr_count]);
    }
}

fn planPage(_: *httpz.Request, res: *httpz.Response) !void {
    const roc_host = g_roc_host.?;
    var html = abi.roc_plan_page();
    defer html.decref(roc_host);

    res.body = try res.arena.dupe(u8, html.asSlice());
    res.content_type = .HTML;
}

fn hostAlloc(length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return abi.DefaultAllocators.rocAlloc(g_roc_host.?, length, alignment);
}

fn hostDealloc(ptr: *anyopaque, alignment: usize) callconv(.c) void {
    abi.DefaultAllocators.rocDealloc(g_roc_host.?, ptr, alignment);
}

fn hostRealloc(ptr: *anyopaque, new_length: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return abi.DefaultAllocators.rocRealloc(g_roc_host.?, ptr, new_length, alignment);
}

fn hostDbg(bytes: [*]const u8, len: usize) callconv(.c) void {
    abi.DefaultHandlers.rocDbg(g_roc_host.?, bytes, len);
}

fn hostExpectFailed(bytes: [*]const u8, len: usize) callconv(.c) void {
    abi.DefaultHandlers.rocExpectFailed(g_roc_host.?, bytes, len);
}

fn hostCrashed(bytes: [*]const u8, len: usize) callconv(.c) void {
    abi.DefaultHandlers.rocCrashed(g_roc_host.?, bytes, len);
}

comptime {
    if (!builtin.is_test) {
        @export(&hostAlloc, .{ .name = "roc_alloc", .visibility = .hidden });
        @export(&hostDealloc, .{ .name = "roc_dealloc", .visibility = .hidden });
        @export(&hostRealloc, .{ .name = "roc_realloc", .visibility = .hidden });
        @export(&hostDbg, .{ .name = "roc_dbg", .visibility = .hidden });
        @export(&hostExpectFailed, .{ .name = "roc_expect_failed", .visibility = .hidden });
        @export(&hostCrashed, .{ .name = "roc_crashed", .visibility = .hidden });
    }
}

/// Platform host entrypoint
fn platform_main(argc: usize, argv: [*][*:0]u8) c_int {
    const io = std.Io.Threaded.global_single_threaded.io();
    _ = argc;
    _ = argv;

    initZigTls();

    var gpa = std.heap.DebugAllocator(.{}){};
    var roc_env = abi.RocEnv{
        .allocator = gpa.allocator(),
        .roc_io = abi.RocIo.default(),
    };

    var roc_host = abi.makeRocHost(&roc_env);
    g_roc_host = &roc_host;

    var server = httpz.Server(void).init(io, gpa.allocator(), .{
        .address = .localhost(8080),
    }, {}) catch |err| {
        std.log.err("failed to start HTTP server: {s}", .{@errorName(err)});
        return 1;
    };
    defer server.deinit();
    defer server.stop();

    var router = server.router(.{}) catch |err| {
        std.log.err("failed to create HTTP router: {s}", .{@errorName(err)});
        return 1;
    };
    router.get("/", planPage, .{});

    std.log.info("serving http://localhost:8080/", .{});
    server.listen() catch |err| {
        std.log.err("HTTP server stopped: {s}", .{@errorName(err)});
        return 1;
    };

    return 0;
}
