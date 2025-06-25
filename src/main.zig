const std = @import("std");

const Imgui = @import("zimgui");

pub fn main() !void {
    const imgui = try Imgui.init(std.heap.page_allocator);
    defer imgui.deinit();

    const io = imgui.getIo().?;
    io.DisplaySize = .{ .x = 100, .y = 100 };

    //Test image fetching
    {
        const font_atlas = imgui.getFontAtlasAsR8().?;

        if (font_atlas.bytes_per_pixel != 1) {
            std.log.err("Font atlas is not r8(bytes_per_pixel = {})", .{font_atlas.bytes_per_pixel});
        }

        const expected_byte_count: usize = @intCast(font_atlas.size[0] * font_atlas.size[1] * font_atlas.bytes_per_pixel);
        if (expected_byte_count != font_atlas.data.len) {
            std.log.err("Font atlas data size incorrect, expected({}) actual({})", .{ expected_byte_count, font_atlas.data.len });
        }

        var white_pixel_counts: usize = 0;
        for (font_atlas.data) |byte| {
            if (byte == 255) {
                white_pixel_counts += 1;
            }
        }

        const white_percentage: f32 = @as(f32, @floatFromInt(white_pixel_counts)) / @as(f32, @floatFromInt(font_atlas.data.len));
        std.log.info("White pixels are {d:0.3}% of the font image", .{white_percentage * 100.0});
    }

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
