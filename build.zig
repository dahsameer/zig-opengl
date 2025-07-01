const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zigopengl",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Windows system libraries for OpenGL
    exe.linkSystemLibrary("opengl32");
    exe.linkSystemLibrary("user32");
    exe.linkSystemLibrary("gdi32");
    exe.linkSystemLibrary("kernel32");

    exe.addIncludePath(b.path("libs/glfw/include"));
    exe.addLibraryPath(b.path("libs/glfw/win-vc2022"));
    exe.linkSystemLibrary("glfw3");

    exe.linkLibC();

    b.installArtifact(exe);

    // Create a custom step to copy DLLs
    const copy_dlls = b.step("copy-dlls", "Copy required DLLs");
    const copy_dll_cmd = b.addSystemCommand(&[_][]const u8{ "xcopy", "/Y", "libs\\glfw\\win-vc2022\\*.dll", "zig-out\\bin\\" });
    copy_dlls.dependOn(&copy_dll_cmd.step);
    b.getInstallStep().dependOn(copy_dlls);

    // Create run step
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
