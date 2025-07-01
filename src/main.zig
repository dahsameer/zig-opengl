const std = @import("std");

const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    std.debug.print("GLFW Error {}: {s}\n", .{ err, description });
}

fn framebuffer_size_callback(_: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    c.glViewport(0, 0, width, height);
}

fn processInput(window: ?*c.GLFWwindow) callconv(.C) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
        c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
    }
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
    defer std.debug.print("Goodbye!\n", .{});

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
    const version = c.glGetString(c.GL_VERSION);
    if (version != null) {
        std.debug.print("OpenGL Version: {s}\n", .{version});
    }

    std.debug.print("Window created successfully! Press ESC or close window to exit.\n", .{});

    c.glViewport(0, 0, 800, 600);
    _ = c.glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    const vertices = [_]f32{ -0.5, -0.5, 0.0, 0.5, -0.5, 0.0, 0.0, 0.5, 0.0 };
    var VAO: c_uint = undefined;
    var VBO: c_uint = undefined;

    c.glGenLists(1, &VAO);
    c.glGenBuffers(1, &VBO);

    defer {
        c.glDeleteVertexArrays(1, &VAO);
        c.glDeleteBuffers(1, &VBO);
    }

    c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);

    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(vertices), vertices, c.GL_STATIC_DRAW);

    // Main loop
    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        // input handling
        processInput(window);

        // rendering commands here
        c.glClearColor(0.6, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // check and call events and swap the buffers
        c.glfwPollEvents();
        c.glfwSwapBuffers(window);
    }
}
