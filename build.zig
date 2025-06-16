const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cimgui = b.addStaticLibrary(.{
        .name = "cimgui",
        .target = target,
        .optimize = optimize,
    });

    cimgui.linkLibCpp();

    const cimgui_sources = [_][]const u8{
        "cimgui/cimgui.cpp",
        "cimgui/imgui/imgui.cpp",
        "cimgui/imgui/imgui_demo.cpp",
        "cimgui/imgui/imgui_draw.cpp",
        "cimgui/imgui/imgui_tables.cpp",
        "cimgui/imgui/imgui_widgets.cpp",
    };

    cimgui.addCSourceFiles(.{
        .files = &cimgui_sources,
        .flags = &[_][]const u8{
            "-DIMGUI_IMPL_API=extern \"C\"",
            "-DIMGUI_DISABLE_OBSOLETE_FUNCTIONS",
            "-fno-exceptions",
            "-fno-rtti",
        },
    });

    cimgui.addIncludePath(b.path("cimgui"));
    cimgui.addIncludePath(b.path("cimgui/imgui"));

    b.installArtifact(cimgui);
}
