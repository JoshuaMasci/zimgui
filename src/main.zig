const std = @import("std");

const Imgui = @import("zimgui");

pub fn main() !void {
    const imgui = try Imgui.init(std.heap.page_allocator);
    defer imgui.deinit();

    const io = imgui.getIo().?;
    io.DisplaySize = .{ .x = 100, .y = 100 };

    const font_atlas = imgui.getFontAtlasAsRGBA32().?;
    _ = font_atlas; // autofix

    for (0..10) |i| {
        _ = i; // autofix

        imgui.newFrame();

        if (imgui.begin("Test Window", null, .{})) {
            imgui.text("This is a label");
            imgui.textFmt("This is a {s} label", .{"formated"});
        }
        imgui.end();

        imgui.endFrame();
        imgui.render();
        _ = imgui.getDrawData();
    }
}
