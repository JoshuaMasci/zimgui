const std = @import("std");
pub const c = @cImport({
    @cDefine("CIMGUI_DEFINE_ENUMS_AND_STRUCTS", "1");
    @cInclude("cimgui/cimgui.h");
});

//Error Types
pub const InitError = error{
    OutOfMemory,
    InitContextFailed,
};

//Types
pub const Vec2 = c.ImVec2;

pub const FontAtlas = struct {
    size: [2]u32,
    bytes_per_pixel: u8,
    data: []const u8,
};

pub const DrawData = struct {
    valid: bool,
    cmd_lists_count: u32,
    total_idx_count: u32,
    total_vtx_count: u32,
    cmd_lists: []const c.ImDrawList,
    display_pos: Vec2,
    display_size: Vec2,
    framebuffer_scale: Vec2,
    owner_viewport: *const c.ImGuiViewport,
};

//Util Functions
fn ImVectorToSlice(comptime T: type, vector: anytype) []const T {
    const len: usize = @intCast(vector.Size);
    if (len == 0) {
        return &.{};
    }

    return vector.Data.*[0..len];
}

const Self = @This();

arena_allocator: *std.heap.ArenaAllocator,
allocator: std.mem.Allocator,
context: *c.ImGuiContext,

pub fn init(allocator: std.mem.Allocator) InitError!Self {
    const context = c.igCreateContext(null);

    if (context == null) {
        return error.InitContextFailed;
    }

    const arena_allocator = allocator.create(std.heap.ArenaAllocator) catch return error.OutOfMemory;
    errdefer allocator.destroy(arena_allocator);

    arena_allocator.* = std.heap.ArenaAllocator.init(allocator);

    return .{
        .arena_allocator = arena_allocator,
        .allocator = arena_allocator.allocator(),
        .context = context.?,
    };
}

pub fn deinit(self: Self) void {
    c.igDestroyContext(self.context);

    const child_allocator = self.arena_allocator.child_allocator;
    self.arena_allocator.deinit();
    child_allocator.destroy(self.arena_allocator);
}

pub fn isContextActive(self: Self) bool {
    return c.igGetCurrentContext() == self.context;
}

pub fn setActive(self: Self) void {
    c.igSetCurrentContext(self.context);
}

pub fn getFontAtlasAsRGBA32(self: Self) ?FontAtlas {
    const io = c.igGetIO_ContextPtr(self.context);
    const fonts = io.*.Fonts;

    var out_pixels: [*c]u8 = undefined;
    var out_width: c_int = 0;
    var out_height: c_int = 0;
    var out_bytes_per_pixel: c_int = 0;

    // Get texture data as RGBA32
    c.ImFontAtlas_GetTexDataAsRGBA32(fonts, &out_pixels, &out_width, &out_height, &out_bytes_per_pixel);

    const pixel_count = @as(usize, @intCast(out_width)) * @as(usize, @intCast(out_height));
    const total_bytes = pixel_count * @as(usize, @intCast(out_bytes_per_pixel));

    // Copy the texture data into a managed buffer
    const buffer = self.allocator.dupe(u8, out_pixels[0..total_bytes]) catch return null;

    return FontAtlas{
        .size = [2]u32{ @intCast(out_width), @intCast(out_height) },
        .bytes_per_pixel = @intCast(out_bytes_per_pixel),
        .data = buffer,
    };
}

pub fn getIo(self: Self) ?*c.ImGuiIO {
    return c.igGetIO_ContextPtr(self.context);
}

pub fn newFrame(self: Self) void {
    _ = self.arena_allocator.reset(.retain_capacity);
    std.debug.assert(self.isContextActive());
    c.igNewFrame();
}

pub fn endFrame(self: Self) void {
    std.debug.assert(self.isContextActive());
    c.igEndFrame();
}

pub fn render(self: Self) void {
    std.debug.assert(self.isContextActive());
    c.igRender();
}

pub fn getDrawData(self: Self) DrawData {
    std.debug.assert(self.isContextActive());
    const c_draw_data = c.igGetDrawData().*;
    return .{
        .valid = c_draw_data.Valid,
        .cmd_lists_count = @intCast(c_draw_data.CmdListsCount),
        .total_idx_count = @intCast(c_draw_data.TotalIdxCount),
        .total_vtx_count = @intCast(c_draw_data.TotalVtxCount),
        .cmd_lists = ImVectorToSlice(c.ImDrawList, c_draw_data.CmdLists),
        .display_pos = c_draw_data.DisplayPos,
        .display_size = c_draw_data.DisplaySize,
        .framebuffer_scale = c_draw_data.FramebufferScale,
        .owner_viewport = c_draw_data.OwnerViewport,
    };
}

pub fn begin(self: Self, name: [:0]const u8, p_open: ?*bool, flags: c.ImGuiWindowFlags) bool {
    std.debug.assert(self.isContextActive());
    return c.igBegin(name, p_open, flags);
}

pub fn end(self: Self) void {
    std.debug.assert(self.isContextActive());
    c.igEnd();
}

pub fn text(self: Self, label: [:0]const u8) void {
    std.debug.assert(self.isContextActive());
    c.igText(label);
}

pub fn textFmt(self: Self, comptime fmt: []const u8, args: anytype) void {
    std.debug.assert(self.isContextActive());
    const label: [:0]const u8 = std.fmt.allocPrintZ(self.allocator, fmt, args) catch |err| std.debug.panic("Failed to fmt string: {}", .{err});
    c.igText(label);
}
