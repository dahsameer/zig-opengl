const std = @import("std");

const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});

const gl = @cImport({
    @cDefine("WIN32_LEAN_AND_MEAN", "1");
    @cInclude("windows.h");
    @cInclude("GL/gl.h");
});

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    std.debug.print("GLFW Error {}: {s}\n", .{ err, description });
}

pub fn main() !void {
    // Set error callback
    _ = c.glfwSetErrorCallback(errorCallback);

    // Initialize GLFW
    if (c.glfwInit() == c.GLFW_FALSE) {
        std.debug.print("Failed to initialize GLFW\n", .{});
        return error.GLFWInitFailed;
    }
    defer c.glfwTerminate();

    // Configure GLFW
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    // Create window
    const window = c.glfwCreateWindow(800, 600, "Zig + GLFW + OpenGL", null, null);
    if (window == null) {
        std.debug.print("Failed to create GLFW window\n", .{});
        return error.WindowCreationFailed;
    }

    c.glfwMakeContextCurrent(window);
    c.glfwSwapInterval(1); // Enable VSync

    // Print OpenGL version
    const version = gl.glGetString(gl.GL_VERSION);
    if (version != null) {
        std.debug.print("OpenGL Version: {s}\n", .{version});
    }

    std.debug.print("Window created successfully! Press ESC or close window to exit.\n", .{});

    // Main loop
    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        c.glfwPollEvents();

        // Handle ESC key
        if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
            c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
        }

        // Clear screen with changing colors
        const time = @as(f64, c.glfwGetTime() * 1000.0) * 0.001;
        const red = (@sin(time) + 1.0) * 0.5;
        const green = (@sin(time + 2.0) + 1.0) * 0.5;
        const blue = (@sin(time + 4.0) + 1.0) * 0.5;

        gl.glClearColor(@floatCast(red), @floatCast(green), @floatCast(blue), 1.0);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);

        c.glfwSwapBuffers(window);
    }

    std.debug.print("Goodbye!\n", .{});
}
