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

const AssetManifest = struct {
    urls: []const []const u8,

    fn deinit(self: AssetManifest, allocator: std.mem.Allocator) void {
        for (self.urls) |url| allocator.free(url);
        allocator.free(self.urls);
    }
};

/// Asset URLs are loaded once at startup from the TypeScript build manifest.
var g_assets: ?AssetManifest = null;

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

fn planPage(req: *httpz.Request, res: *httpz.Response) !void {
    const roc_host = g_roc_host.?;
    const query = try req.query();
    const kind = query.get("kind") orelse "";
    const id = query.get("id") orelse "";
    var html = abi.roc_plan_page(
        abi.RocStr.fromSlice(kind, roc_host),
        abi.RocStr.fromSlice(id, roc_host),
    );
    defer html.decref(roc_host);

    res.content_type = .HTML;
    res.header("Cache-Control", "no-cache");

    const writer = res.writer();
    try writer.writeAll("<!doctype html><html><head><meta charset=\"utf-8\">");
    for (g_assets.?.urls) |url| {
        if (std.mem.endsWith(u8, url, ".css")) {
            try writer.print("<link rel=\"stylesheet\" href=\"{s}\">", .{url});
        } else {
            try writer.print("<script type=\"module\" src=\"{s}\"></script>", .{url});
        }
    }
    try writer.writeAll("</head><body>");
    try writer.writeAll(html.asSlice());
    try writer.writeAll("</body></html>");
}

fn assetFile(req: *httpz.Request, res: *httpz.Response) !void {
    const requested_url = req.url.path;
    const is_known_asset = for (g_assets.?.urls) |url| {
        if (std.mem.eql(u8, requested_url, url)) break true;
        if (std.mem.endsWith(u8, requested_url, ".map") and
            std.mem.eql(u8, requested_url[0 .. requested_url.len - ".map".len], url)) break true;
    } else false;
    if (!is_known_asset) {
        res.setStatus(.not_found);
        return;
    }

    const is_source_map = std.mem.endsWith(u8, requested_url, ".map");
    const filename = requested_url["/assets/".len..];
    const asset_path = try std.fmt.allocPrint(res.arena, "dist/{s}", .{filename});
    const buffer = try res.arena.alloc(u8, 10 * 1024 * 1024);
    const io = std.Io.Threaded.global_single_threaded.io();
    const bytes = std.Io.Dir.cwd().readFile(io, asset_path, buffer) catch |err| switch (err) {
        error.FileNotFound => {
            res.setStatus(.not_found);
            return;
        },
        else => return err,
    };

    res.body = bytes;
    if (std.mem.endsWith(u8, requested_url, ".css")) {
        res.header("Content-Type", "text/css; charset=utf-8");
    } else {
        res.content_type = if (is_source_map) .JSON else .JS;
    }
    res.header(
        "Cache-Control",
        if (is_source_map) "no-cache" else "public, max-age=31536000, immutable",
    );
}

fn mcpEndpoint(req: *httpz.Request, res: *httpz.Response) !void {
    if (req.method != .POST) {
        res.content_type = .JSON;
        res.header("Cache-Control", "no-cache");
        try writeMcpEndpointMetadata(res.writer());
        return;
    }

    var body: std.Io.Writer.Allocating = .init(res.arena);
    var reader = try req.reader(1024 * 1024);
    var buffer: [8192]u8 = undefined;
    while (true) {
        const read = try reader.read(&buffer);
        if (read == 0) break;
        try body.writer.writeAll(buffer[0..read]);
    }

    res.content_type = .JSON;
    res.header("Cache-Control", "no-cache");

    const status = try writeMcpJsonRpcResponse(res.arena, res.writer(), body.written(), rocMcpProviders());
    res.status = @intFromEnum(status);
}

const McpProviders = struct {
    write_resources: *const fn (*std.Io.Writer) anyerror!void,
    write_resource_content: *const fn ([]const u8, *std.Io.Writer) anyerror!void,
    write_prompts: *const fn (*std.Io.Writer) anyerror!void,
    write_prompt: *const fn ([]const u8, *std.Io.Writer) anyerror!void,
    write_implementation_targets: *const fn (*std.Io.Writer) anyerror!void,
};

const builtin_status_resource_json = "{\"uri\":\"rocitect://references/status-updates\",\"name\":\"Status update guidance\",\"description\":\"Host response status behavior to preserve when changing MCP code.\",\"mimeType\":\"text/plain\"}";
const builtin_status_resource_text = "Status update guidance from src/host.zig: malformed JSON returns HTTP 400 with JSON-RPC parse error -32700; supported JSON-RPC methods return HTTP 200; unknown methods return -32601; unknown tools return -32602. Preserve these statuses when updating MCP endpoint behavior.";

fn writeMcpEndpointMetadata(writer: *std.Io.Writer) !void {
    try writer.writeAll("{\"name\":\"rocitect\",\"endpoint\":\"/mcp\",\"transport\":\"streamable-http\"}");
}

fn writeMcpJsonRpcResponse(arena: std.mem.Allocator, writer: *std.Io.Writer, body: []const u8, providers: McpProviders) !std.http.Status {
    var parsed = std.json.parseFromSlice(std.json.Value, arena, body, .{}) catch {
        try writer.writeAll("{\"jsonrpc\":\"2.0\",\"id\":null,\"error\":{\"code\":-32700,\"message\":\"Parse error\"}}");
        return .bad_request;
    };
    defer parsed.deinit();

    if (parsed.value != .object) {
        try writeJsonRpcError(writer, .null, -32600, "Invalid request");
        return .ok;
    }

    const request = parsed.value.object;
    const id: std.json.Value = request.get("id") orelse .null;
    const method_value = request.get("method") orelse {
        try writeJsonRpcError(writer, id, -32600, "Missing method");
        return .ok;
    };
    if (method_value != .string) {
        try writeJsonRpcError(writer, id, -32600, "Invalid method");
        return .ok;
    }

    const method = method_value.string;
    if (std.mem.eql(u8, method, "initialize")) {
        try writeJsonRpcResultPrefix(writer, id);
        try writer.writeAll("{\"protocolVersion\":\"2024-11-05\",\"capabilities\":{\"resources\":{},\"prompts\":{},\"tools\":{}},\"serverInfo\":{\"name\":\"rocitect\",\"version\":\"0.1.0\"}}");
        try writeJsonRpcResultSuffix(writer);
    } else if (std.mem.eql(u8, method, "resources/list")) {
        try writeJsonRpcResultPrefix(writer, id);
        try writer.writeAll("{\"resources\":");
        try writeMcpResourcesWithBuiltins(arena, writer, providers);
        try writer.writeAll("}");
        try writeJsonRpcResultSuffix(writer);
    } else if (std.mem.eql(u8, method, "resources/read")) {
        const uri = getStringParam(request.get("params"), "uri") orelse "unknown";
        const resource_key = resourceKey(uri);
        try writeJsonRpcResultPrefix(writer, id);
        try writer.writeAll("{\"contents\":[{\"uri\":");
        try writeJsonString(writer, uri);
        try writer.writeAll(",\"mimeType\":\"text/plain\",\"text\":");
        if (std.mem.eql(u8, resource_key, "status-updates")) {
            try writeJsonString(writer, builtin_status_resource_text);
        } else {
            try providers.write_resource_content(resource_key, writer);
        }
        try writer.writeAll("}]}");
        try writeJsonRpcResultSuffix(writer);
    } else if (std.mem.eql(u8, method, "prompts/list")) {
        try writeJsonRpcResultPrefix(writer, id);
        try writer.writeAll("{\"prompts\":");
        try providers.write_prompts(writer);
        try writer.writeAll("}");
        try writeJsonRpcResultSuffix(writer);
    } else if (std.mem.eql(u8, method, "prompts/get")) {
        const name = getStringParam(request.get("params"), "name") orelse "implement-function";
        const prompt_name = if (std.mem.eql(u8, name, "implement-test-suite")) "implement-test-suite" else "implement-function";
        try writeJsonRpcResultPrefix(writer, id);
        try writer.writeAll("{\"description\":");
        try writeJsonString(writer, prompt_name);
        try writer.writeAll(",\"messages\":[{\"role\":\"user\",\"content\":{\"type\":\"text\",\"text\":");
        try providers.write_prompt(prompt_name, writer);
        try writer.writeAll("}}]}");
        try writeJsonRpcResultSuffix(writer);
    } else if (std.mem.eql(u8, method, "tools/list")) {
        try writeJsonRpcResultPrefix(writer, id);
        try writer.writeAll("{\"tools\":[{\"name\":\"list_implementation_targets\",\"description\":\"List available functions and test suites to implement.\",\"inputSchema\":{\"type\":\"object\",\"properties\":{}}}]}");
        try writeJsonRpcResultSuffix(writer);
    } else if (std.mem.eql(u8, method, "tools/call")) {
        const name = getStringParam(request.get("params"), "name") orelse "";
        if (!std.mem.eql(u8, name, "list_implementation_targets")) {
            try writeJsonRpcError(writer, id, -32602, "Unknown tool");
            return .ok;
        }
        try writeJsonRpcResultPrefix(writer, id);
        try writer.writeAll("{\"content\":[{\"type\":\"text\",\"text\":");
        try providers.write_implementation_targets(writer);
        try writer.writeAll("}]}");
        try writeJsonRpcResultSuffix(writer);
    } else {
        try writeJsonRpcError(writer, id, -32601, "Method not found");
    }

    return .ok;
}

fn writeMcpResourcesWithBuiltins(arena: std.mem.Allocator, writer: *std.Io.Writer, providers: McpProviders) !void {
    var app_resources: std.Io.Writer.Allocating = .init(arena);
    try providers.write_resources(&app_resources.writer);

    const app_json = std.mem.trim(u8, app_resources.written(), " \n\r\t");
    if (std.mem.eql(u8, app_json, "[]")) {
        try writer.writeAll("[");
        try writer.writeAll(builtin_status_resource_json);
        return writer.writeAll("]");
    }

    if (app_json.len >= 2 and app_json[0] == '[' and app_json[app_json.len - 1] == ']') {
        try writer.writeAll("[");
        try writer.writeAll(builtin_status_resource_json);
        try writer.writeAll(",");
        try writer.writeAll(app_json[1 .. app_json.len - 1]);
        return writer.writeAll("]");
    }

    return error.InvalidMcpResources;
}

fn rocMcpProviders() McpProviders {
    return .{
        .write_resources = writeRocMcpResources,
        .write_resource_content = writeRocMcpResourceContent,
        .write_prompts = writeRocMcpPrompts,
        .write_prompt = writeRocMcpPrompt,
        .write_implementation_targets = writeRocMcpImplementationTargets,
    };
}

fn writeRocMcpResources(writer: *std.Io.Writer) !void {
    var resources = abi.roc_mcp_resources();
    defer resources.decref(g_roc_host.?);
    try writer.writeAll(resources.asSlice());
}

fn writeRocMcpResourceContent(resource_key: []const u8, writer: *std.Io.Writer) !void {
    const roc_key = abi.RocStr.fromSlice(resource_key, g_roc_host.?);
    var content = abi.roc_mcp_read_resource(roc_key);
    defer content.decref(g_roc_host.?);
    try writeJsonString(writer, content.asSlice());
}

fn writeRocMcpPrompts(writer: *std.Io.Writer) !void {
    var prompts = abi.roc_mcp_prompts();
    defer prompts.decref(g_roc_host.?);
    try writer.writeAll(prompts.asSlice());
}

fn writeRocMcpPrompt(prompt_name: []const u8, writer: *std.Io.Writer) !void {
    const roc_name = abi.RocStr.fromSlice(prompt_name, g_roc_host.?);
    var prompt = abi.roc_mcp_prompt(roc_name);
    defer prompt.decref(g_roc_host.?);
    try writeJsonString(writer, prompt.asSlice());
}

fn writeRocMcpImplementationTargets(writer: *std.Io.Writer) !void {
    var targets = abi.roc_mcp_implementation_targets();
    defer targets.decref(g_roc_host.?);
    try writeJsonString(writer, targets.asSlice());
}

fn getStringParam(params: ?std.json.Value, name: []const u8) ?[]const u8 {
    const params_value = params orelse return null;
    if (params_value != .object) return null;
    const value = params_value.object.get(name) orelse return null;
    if (value != .string) return null;
    return value.string;
}

fn resourceKey(uri: []const u8) []const u8 {
    if (std.mem.eql(u8, uri, "rocitect://references/implementation-guidance")) return "implementation-guidance";
    if (std.mem.eql(u8, uri, "rocitect://references/progress-tracking")) return "progress-tracking";
    if (std.mem.eql(u8, uri, "rocitect://references/go-language-manual")) return "go-language-manual";
    if (std.mem.eql(u8, uri, "rocitect://references/weather-gov-api-docs")) return "weather-gov-api-docs";
    if (std.mem.eql(u8, uri, "rocitect://references/status-updates")) return "status-updates";
    return "unknown";
}

fn writeJsonRpcError(writer: *std.Io.Writer, id: std.json.Value, code: i32, message: []const u8) !void {
    try writer.writeAll("{\"jsonrpc\":\"2.0\",\"id\":");
    try std.json.Stringify.value(id, .{}, writer);
    try writer.print(",\"error\":{{\"code\":{},\"message\":", .{code});
    try writeJsonString(writer, message);
    try writer.writeAll("}}");
}

fn writeJsonRpcResultPrefix(writer: anytype, id: std.json.Value) !void {
    try writer.writeAll("{\"jsonrpc\":\"2.0\",\"id\":");
    try std.json.Stringify.value(id, .{}, writer);
    try writer.writeAll(",\"result\":");
}

fn writeJsonRpcResultSuffix(writer: anytype) !void {
    try writer.writeAll("}");
}

fn writeJsonString(writer: anytype, value: []const u8) !void {
    try writer.writeAll("\"");
    for (value) |byte| {
        switch (byte) {
            '"' => try writer.writeAll("\\\""),
            '\\' => try writer.writeAll("\\\\"),
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            0x08 => try writer.writeAll("\\b"),
            0x0c => try writer.writeAll("\\f"),
            0...0x07, 0x0b, 0x0e...0x1f => try writer.print("\\u{x:0>4}", .{byte}),
            else => try writer.writeAll(&.{byte}),
        }
    }
    try writer.writeAll("\"");
}

fn loadAssetManifest(io: std.Io, allocator: std.mem.Allocator) !AssetManifest {
    const manifest_buffer = try allocator.alloc(u8, 1024 * 1024);
    defer allocator.free(manifest_buffer);
    const manifest_bytes = try std.Io.Dir.cwd().readFile(io, "dist/manifest.json", manifest_buffer);

    var parsed = try std.json.parseFromSlice(std.json.Value, allocator, manifest_bytes, .{});
    defer parsed.deinit();

    if (parsed.value != .object) return error.InvalidManifest;
    var urls = std.ArrayList([]const u8).empty;
    errdefer {
        for (urls.items) |url| allocator.free(url);
        urls.deinit(allocator);
    }

    var iterator = parsed.value.object.iterator();
    while (iterator.next()) |entry| {
        if (entry.value_ptr.* != .string) return error.InvalidManifest;
        const url = entry.value_ptr.string;
        if (!isAssetUrl(url)) {
            return error.InvalidManifest;
        }
        try urls.append(allocator, try allocator.dupe(u8, url));
    }

    std.mem.sort([]const u8, urls.items, {}, stringLessThan);
    return .{ .urls = try urls.toOwnedSlice(allocator) };
}

fn stringLessThan(_: void, left: []const u8, right: []const u8) bool {
    return std.mem.order(u8, left, right) == .lt;
}

fn isAssetUrl(url: []const u8) bool {
    if (!std.mem.startsWith(u8, url, "/assets/") or
        (!std.mem.endsWith(u8, url, ".js") and !std.mem.endsWith(u8, url, ".css"))) return false;
    for (url["/assets/".len..]) |byte| {
        if (!std.ascii.isAlphanumeric(byte) and byte != '-' and byte != '_' and byte != '.') return false;
    }
    return true;
}

test "asset URLs are safe flat JavaScript or CSS paths" {
    try std.testing.expect(isAssetUrl("/assets/feature-a-ABC123.js"));
    try std.testing.expect(isAssetUrl("/assets/styles-ABC123.css"));
    try std.testing.expect(!isAssetUrl("/assets/nested/feature-a.js"));
    try std.testing.expect(!isAssetUrl("/assets/feature-a.js.map"));
    try std.testing.expect(!isAssetUrl("/assets/feature-a.js\""));
}

const test_mcp_providers = McpProviders{
    .write_resources = writeTestMcpResources,
    .write_resource_content = writeTestMcpResourceContent,
    .write_prompts = writeTestMcpPrompts,
    .write_prompt = writeTestMcpPrompt,
    .write_implementation_targets = writeTestMcpImplementationTargets,
};

fn writeTestMcpResources(writer: *std.Io.Writer) !void {
    try writer.writeAll("[{\"uri\":\"rocitect://references/implementation-guidance\",\"name\":\"Implementation guidance\"}]");
}

fn writeTestMcpResourceContent(resource_key: []const u8, writer: *std.Io.Writer) !void {
    if (std.mem.eql(u8, resource_key, "implementation-guidance")) {
        return writeJsonString(writer, "Use the implementation guidance.");
    }
    try writeJsonString(writer, "Unknown resource.");
}

fn writeTestMcpPrompts(writer: *std.Io.Writer) !void {
    try writer.writeAll("[{\"name\":\"implement-function\"},{\"name\":\"implement-test-suite\"}]");
}

fn writeTestMcpPrompt(prompt_name: []const u8, writer: *std.Io.Writer) !void {
    if (std.mem.eql(u8, prompt_name, "implement-test-suite")) {
        return writeJsonString(writer, "Write tests for the target function.");
    }
    try writeJsonString(writer, "Implement the target function.");
}

fn writeTestMcpImplementationTargets(writer: *std.Io.Writer) !void {
    try writeJsonString(writer, "Available functions to implement:\n- function:get-weather-forecast GetWeatherForecast");
}

fn testMcpResponse(body: []const u8) !struct { status: std.http.Status, body: []const u8 } {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    errdefer arena_state.deinit();

    var out: std.Io.Writer.Allocating = .init(std.testing.allocator);
    errdefer out.deinit();

    const status = try writeMcpJsonRpcResponse(arena_state.allocator(), &out.writer, body, test_mcp_providers);
    arena_state.deinit();
    return .{ .status = status, .body = try out.toOwnedSlice() };
}

fn expectMcpResponseContains(body: []const u8, expected: []const u8) !void {
    const response = try testMcpResponse(body);
    defer std.testing.allocator.free(response.body);

    try std.testing.expectEqual(std.http.Status.ok, response.status);
    try std.testing.expect(std.mem.containsAtLeast(u8, response.body, 1, expected));
}

test "MCP endpoint metadata describes the streamable HTTP endpoint" {
    var out: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer out.deinit();

    try writeMcpEndpointMetadata(&out.writer);

    try std.testing.expectEqualStrings(
        "{\"name\":\"rocitect\",\"endpoint\":\"/mcp\",\"transport\":\"streamable-http\"}",
        out.written(),
    );
}

test "MCP endpoint initialize returns protocol capabilities" {
    try expectMcpResponseContains(
        "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\"}",
        "\"capabilities\":{\"resources\":{},\"prompts\":{},\"tools\":{}}",
    );
}

test "MCP endpoint resources/list returns Roc resources" {
    try expectMcpResponseContains(
        "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"resources/list\"}",
        "\"uri\":\"rocitect://references/implementation-guidance\"",
    );
}

test "MCP endpoint resources/list always includes status update guidance" {
    try expectMcpResponseContains(
        "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"resources/list\"}",
        "\"uri\":\"rocitect://references/status-updates\"",
    );
}

test "MCP endpoint resources/read returns selected resource content" {
    try expectMcpResponseContains(
        "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"resources/read\",\"params\":{\"uri\":\"rocitect://references/implementation-guidance\"}}",
        "\"text\":\"Use the implementation guidance.\"",
    );
}

test "MCP endpoint resources/read returns host-owned status update guidance" {
    try expectMcpResponseContains(
        "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"resources/read\",\"params\":{\"uri\":\"rocitect://references/status-updates\"}}",
        "malformed JSON returns HTTP 400",
    );
}

test "MCP endpoint prompts/list returns Roc prompts" {
    try expectMcpResponseContains(
        "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"prompts/list\"}",
        "\"prompts\":[{\"name\":\"implement-function\"}",
    );
}

test "MCP endpoint prompts/get returns function prompt by default" {
    try expectMcpResponseContains(
        "{\"jsonrpc\":\"2.0\",\"id\":5,\"method\":\"prompts/get\",\"params\":{\"name\":\"implement-function\"}}",
        "\"text\":\"Implement the target function.\"",
    );
}

test "MCP endpoint prompts/get returns test suite prompt" {
    try expectMcpResponseContains(
        "{\"jsonrpc\":\"2.0\",\"id\":6,\"method\":\"prompts/get\",\"params\":{\"name\":\"implement-test-suite\"}}",
        "\"description\":\"implement-test-suite\"",
    );
}

test "MCP endpoint tools/list returns implementation target tool" {
    try expectMcpResponseContains(
        "{\"jsonrpc\":\"2.0\",\"id\":7,\"method\":\"tools/list\"}",
        "\"name\":\"list_implementation_targets\"",
    );
}

test "MCP endpoint tools/call returns implementation targets" {
    try expectMcpResponseContains(
        "{\"jsonrpc\":\"2.0\",\"id\":8,\"method\":\"tools/call\",\"params\":{\"name\":\"list_implementation_targets\"}}",
        "function:get-weather-forecast GetWeatherForecast",
    );
}

test "MCP endpoint rejects malformed JSON" {
    const response = try testMcpResponse("{");
    defer std.testing.allocator.free(response.body);

    try std.testing.expectEqual(std.http.Status.bad_request, response.status);
    try std.testing.expect(std.mem.containsAtLeast(u8, response.body, 1, "\"code\":-32700"));
}

test "MCP endpoint rejects unknown methods and tools" {
    try expectMcpResponseContains(
        "{\"jsonrpc\":\"2.0\",\"id\":9,\"method\":\"unknown/method\"}",
        "\"code\":-32601",
    );
    try expectMcpResponseContains(
        "{\"jsonrpc\":\"2.0\",\"id\":10,\"method\":\"tools/call\",\"params\":{\"name\":\"unknown_tool\"}}",
        "\"code\":-32602",
    );
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
    g_assets = loadAssetManifest(io, gpa.allocator()) catch |err| {
        std.log.err("failed to load dist/manifest.json: {s}; run npm run build", .{@errorName(err)});
        return 1;
    };
    defer g_assets.?.deinit(gpa.allocator());

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
    router.get("/mcp", mcpEndpoint, .{});
    router.post("/mcp", mcpEndpoint, .{});
    router.get("/assets/*", assetFile, .{});

    std.log.info("serving http://localhost:8080/", .{});
    server.listen() catch |err| {
        std.log.err("HTTP server stopped: {s}", .{@errorName(err)});
        return 1;
    };

    return 0;
}
