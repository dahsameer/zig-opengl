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

fn processInput(window: ?*c.GLFWwindow) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
        c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
    }
}

pub fn main() !void {
    // setting a callback for error in glfw
    _ = c.glfwSetErrorCallback(errorCallback);

    // glfw: initialize and configure
    if (c.glfwInit() == c.GLFW_FALSE) {
        std.debug.print("Failed to initialize GLFW\n", .{});
        return error.GLFWInitFailed;
    }
    defer c.glfwTerminate();
    defer std.debug.print("Goodbye!\n", .{});

    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 4);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 6);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    // glfw window creation
    const window = c.glfwCreateWindow(800, 600, "Zig + GLFW + OpenGL", null, null);
    if (window == null) {
        std.debug.print("Failed to create GLFW window\n", .{});
        return error.WindowCreationFailed;
    }

    c.glfwMakeContextCurrent(window);
    c.glfwSwapInterval(1);

    // glad: load all opengl function pointers
    std.debug.print("Initializing GLAD...\n", .{});
    if (c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress)) == 0) {
        std.debug.print("Failed to initialize GLAD\n", .{});
        return error.GLADInitFailed;
    }

    const version = c.glGetString(c.GL_VERSION);
    if (version != null) {
        std.debug.print("OpenGL Version: {s}\n", .{version});
    }

    std.debug.print("Window created successfully! Press ESC or close window to exit.\n", .{});

    c.glViewport(0, 0, 800, 600);
    _ = c.glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    // shader/program status check
    var success: c_int = undefined;
    var infoLog: [512:0]u8 = undefined;

    // read shader source code from shader files, we have 2 files frag.glsl and vert.glsl
    const vertexShaderSource: [*c]const u8 = @embedFile("resources/vert.glsl");
    const fragmentShaderSource: [*c]const u8 = @embedFile("resources/frag.glsl");

    // vertex shader
    const vertexShader: c_uint = c.glCreateShader(c.GL_VERTEX_SHADER);

    c.glShaderSource(vertexShader, 1, @ptrCast(&vertexShaderSource), null);
    c.glCompileShader(vertexShader);

    c.glGetShaderiv(vertexShader, c.GL_COMPILE_STATUS, &success);
    if (success == c.GL_FALSE) {
        c.glGetShaderInfoLog(vertexShader, 512, null, @ptrCast(&infoLog));
        std.debug.print("shader error: {s}", .{infoLog});
    }

    // fragment shader
    const fragmentShader: c_uint = c.glCreateShader(c.GL_FRAGMENT_SHADER);

    c.glShaderSource(fragmentShader, 1, @ptrCast(&fragmentShaderSource), null);
    c.glCompileShader(fragmentShader);

    c.glGetShaderiv(fragmentShader, c.GL_COMPILE_STATUS, &success);
    if (success == c.GL_FALSE) {
        c.glGetShaderInfoLog(fragmentShader, 512, null, @ptrCast(&infoLog));
        std.debug.print("shader error: {s}\n", .{infoLog});
    }

    // link shaders
    const shaderProgram = c.glCreateProgram();

    c.glAttachShader(shaderProgram, vertexShader);
    c.glAttachShader(shaderProgram, fragmentShader);
    c.glLinkProgram(shaderProgram);

    // check for linking error
    c.glGetProgramiv(shaderProgram, c.GL_LINK_STATUS, &success);
    if (success == c.GL_FALSE) {
        c.glGetProgramInfoLog(shaderProgram, 512, null, &infoLog);
        std.debug.print("program link error: {s}\n", .{infoLog});
    }

    c.glDeleteShader(vertexShader);
    c.glDeleteShader(fragmentShader);

    defer c.glDeleteProgram(shaderProgram);

    const vertices = [_]f32{
        0.5, -0.5, 0.0, 1.0, 0.0, 0.0, // bottom right
        -0.5, -0.5, 0.0, 0.0, 1.0, 0.0, // bottom let
        0.0, 0.5, 0.0, 0.0, 0.0, 1.0, // top
    };

    // const indices = [_]u32{
    //     0, 1, 3, // first triangle
    //     1, 2, 3, // second triangle
    // };

    var VAO: c_uint = undefined;
    var VBO: c_uint = undefined;
    // var EBO: c_uint = undefined;

    c.glGenVertexArrays(1, &VAO);
    c.glGenBuffers(1, &VBO);
    // c.glGenBuffers(1, &EBO);

    defer {
        c.glDeleteVertexArrays(1, &VAO);
        c.glDeleteBuffers(1, &VBO);
        // c.glDeleteBuffers(1, &EBO);
    }

    // bind the vertex array object first, kthen bind and set vertex buffers and then configure vertex attributes
    c.glBindVertexArray(VAO);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, VBO);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, c.GL_STATIC_DRAW);

    // c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, EBO);
    // c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices)), &indices, c.GL_STATIC_DRAW);

    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @ptrFromInt(0));
    c.glEnableVertexAttribArray(0);

    c.glVertexAttribPointer(
        1,
        3,
        c.GL_FLOAT,
        c.GL_FALSE,
        6 * @sizeOf(f32),
        @ptrFromInt(3 * @sizeOf(f32)),
    );
    c.glEnableVertexAttribArray(1);

    c.glBindBuffer(c.GL_ARRAY_BUFFER, 0);
    c.glBindVertexArray(0);

    // c.glPolygonMode(c.GL_FRONT_AND_BACK, c.GL_LINE);

    while (c.glfwWindowShouldClose(window) == c.GLFW_FALSE) {
        processInput(window);

        c.glClearColor(0.5, 0.3, 0.3, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        const timeValue: f32 = @floatCast(c.glfwGetTime());
        const redValue: f32 = (@sin(timeValue + 0.0) * 0.5) + 0.5;
        const greenValue: f32 = (@sin(timeValue + 2.0) * 0.5) + 0.5;
        const blueValue: f32 = (@sin(timeValue + 4.0) * 0.5) + 0.5;

        const vertexColorLocation = c.glGetUniformLocation(shaderProgram, "ourColor");

        c.glUseProgram(shaderProgram);
        c.glBindVertexArray(VAO);
        c.glUniform4f(vertexColorLocation, redValue, greenValue, blueValue, 1.0);
        // c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
