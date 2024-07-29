const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

var procs: gl.ProcTable = undefined;

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window = glfw.Window.create(800, 800, "fuck opengl", null, null, .{}) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();

    glfw.makeContextCurrent(window);

    if (!procs.init(glfw.getProcAddress)) return error.InitFailed;

    // Make the procedure table current on the calling thread.
    gl.makeProcTableCurrent(&procs);
    defer gl.makeProcTableCurrent(null);

    const vertices = [_]f32{
        -0.5, -0.5, 1,   0,   0,
        -0.5, 0.5,  0,   1,   0,
        0.5,  0.5,  0,   0,   1,
        0.5,  -0.5, 0.5, 0.5, 0.5,
    };
    const indices = [_]u32{
        0, 2, 1,
        0, 3, 2,
    };

    var vbo: u32 = undefined;
    var vao: u32 = undefined;
    var ibo: u32 = undefined;

    gl.GenVertexArrays(1, @ptrCast(&vao));
    gl.GenBuffers(1, @ptrCast(&vbo));
    defer gl.DeleteBuffers(1, @ptrCast(&vbo));

    gl.BindVertexArray(vao);
    defer gl.BindVertexArray(0);

    gl.GenBuffers(1, @ptrCast(&ibo));
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ibo);
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices)), &indices, gl.STATIC_DRAW);
    defer gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);

    gl.BindBuffer(gl.ARRAY_BUFFER, vbo);
    defer gl.BindBuffer(gl.ARRAY_BUFFER, 0);

    gl.BufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.STATIC_DRAW);

    gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 5 * @sizeOf(f32), 0);
    gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 5 * @sizeOf(f32), 2 * @sizeOf(f32));
    gl.EnableVertexAttribArray(0);
    gl.EnableVertexAttribArray(1);

    //shader
    const vertexShaderSource: [*]const [*]const u8 = @ptrCast(&@embedFile("resources/shaders/vert.glsl"));
    const fragmentShaderSource: [*]const [*]const u8 = @ptrCast(&@embedFile("resources/shaders/frag.glsl"));

    const vertShader: u32 = gl.CreateShader(gl.VERTEX_SHADER);
    const fragShader: u32 = gl.CreateShader(gl.FRAGMENT_SHADER);

    gl.ShaderSource(vertShader, 1, vertexShaderSource, null);
    gl.CompileShader(vertShader);
    gl.ShaderSource(fragShader, 1, fragmentShaderSource, null);
    gl.CompileShader(fragShader);

    const shader = gl.CreateProgram();
    gl.AttachShader(shader, vertShader);
    gl.AttachShader(shader, fragShader);
    gl.LinkProgram(shader);

    //shaders not necessary after linking to the program
    gl.DeleteShader(vertShader);
    gl.DeleteShader(fragShader);

    main_loop: while (true) {
        glfw.waitEvents();
        if (window.shouldClose()) break :main_loop;

        gl.ClearColor(0.07, 0.13, 0.17, 1);
        gl.Clear(gl.COLOR_BUFFER_BIT);

        gl.UseProgram(shader);
        gl.BindVertexArray(vao);

        gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, 0);

        window.swapBuffers();
    }
}
