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

    const zimgui_module = b.addModule("zimgui", .{
        .root_source_file = b.path("src/zimgui.zig"),
    });
    zimgui_module.linkLibrary(cimgui);
    zimgui_module.addIncludePath(b.path(""));

    //Test Exe
    const exe = b.addExecutable(.{
        .name = "test_app",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zimgui", zimgui_module);

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run test app");
    run_step.dependOn(&run_cmd.step);
}
