const std = @import("std");
const lib = @import("./lib.zig");
const backend = lib.backend;
const zgui = lib.zgui;
const zgpu = lib.zgpu;
const wgpu = lib.wgpu;
const modules = lib.modules;
// const math = lib.math;
const math = @import("math");
const Mat4 = math.Mat4x4;
const Vec3 = math.Vec3;
const wgsl_vs =
    \\  @group(0) @binding(0) var<uniform> object_to_clip: mat4x4<f32>;
    \\  struct VertexOut {
    \\      @builtin(position) position_clip: vec4<f32>,
    \\      @location(0) color: vec3<f32>,
    \\  }
    \\  @vertex fn main(
    \\      @location(0) position: vec3<f32>,
    \\      @location(1) color: vec3<f32>,
    \\  ) -> VertexOut {
    \\      var output: VertexOut;
    \\      output.position_clip = object_to_clip vec4(position, 1.0);
    \\      output.color = color;
    \\      return output;
    \\  }
;
const wgsl_fs =
    \\  @fragment fn main(
    \\      @location(0) color: vec3<f32>,
    \\  ) -> @location(0) vec4<f32> {
    \\      return vec4(color, 1.0);
    \\  }
;
const GpuMesh = struct {
    gctx: *zgpu.GraphicsContext,

    pipeline: zgpu.RenderPipelineHandle,
    bind_group: zgpu.BindGroupHandle,

    vertex_buffer: zgpu.BufferHandle,
    index_buffer: zgpu.BufferHandle,

    depth_texture: zgpu.TextureHandle,
    depth_texture_view: zgpu.TextureViewHandle,
};
var gpuMesh: GpuMesh = undefined;
const Vertex = struct {
    position: [3]f32,
    color: [3]f32,
};
var vs_module: zgpu.wgpu.ShaderModule = undefined;
var fs_module: zgpu.wgpu.ShaderModule = undefined;
fn on_init(appBackend: *backend.AppBackend) !void {
    const gctx = appBackend.gctx;
    vs_module = zgpu.createWgslShaderModule(gctx.device, wgsl_vs, "vs");
    defer vs_module.release();
    fs_module = zgpu.createWgslShaderModule(gctx.device, wgsl_fs, "fs");
    defer fs_module.release();

    const bind_group_layout = gctx.createBindGroupLayout(&.{
        zgpu.bufferEntry(0, .{ .vertex = true }, .uniform, true, 0),
    });
    defer gctx.releaseResource(bind_group_layout);
    const pipeline_layout = gctx.createPipelineLayout(&.{bind_group_layout});
    defer gctx.releaseResource(pipeline_layout);

    const color_targets = [_]wgpu.ColorTargetState{.{
        .format = zgpu.GraphicsContext.swapchain_format,
    }};

    const vertex_attributes = [_]wgpu.VertexAttribute{
        .{ .format = .float32x3, .offset = 0, .shader_location = 0 },
        .{ .format = .float32x3, .offset = @offsetOf(Vertex, "color"), .shader_location = 1 },
    };
    const vertex_buffers = [_]wgpu.VertexBufferLayout{.{
        .array_stride = @sizeOf(Vertex),
        .attribute_count = vertex_attributes.len,
        .attributes = &vertex_attributes,
    }};

    const pipeline_descriptor = wgpu.RenderPipelineDescriptor{
        .vertex = wgpu.VertexState{
            .module = vs_module,
            .entry_point = "main",
            .buffer_count = vertex_buffers.len,
            .buffers = &vertex_buffers,
        },
        .primitive = wgpu.PrimitiveState{
            .front_face = .ccw,
            .cull_mode = .none,
            .topology = .triangle_list,
        },
        .depth_stencil = &wgpu.DepthStencilState{
            .format = .depth32_float,
            .depth_write_enabled = true,
            .depth_compare = .less,
        },
        .fragment = &wgpu.FragmentState{
            .module = fs_module,
            .entry_point = "main",
            .target_count = color_targets.len,
            .targets = &color_targets,
        },
    };
    const pipeline = gctx.createRenderPipeline(pipeline_layout, pipeline_descriptor);

    const bind_group = gctx.createBindGroup(bind_group_layout, &.{
        .{ .binding = 0, .buffer_handle = gctx.uniforms.buffer, .offset = 0, .size = @sizeOf(Mat4) },
    });

    // Create a vertex buffer.
    const vertex_buffer = gctx.createBuffer(.{
        .usage = .{ .copy_dst = true, .vertex = true },
        .size = 3 * @sizeOf(Vertex),
    });
    const vertex_data = [_]Vertex{
        .{ .position = [3]f32{ 0.0, 0.5, 0.0 }, .color = [3]f32{ 1.0, 0.0, 0.0 } },
        .{ .position = [3]f32{ -0.5, -0.5, 0.0 }, .color = [3]f32{ 0.0, 1.0, 0.0 } },
        .{ .position = [3]f32{ 0.5, -0.5, 0.0 }, .color = [3]f32{ 0.0, 0.0, 1.0 } },
    };
    gctx.queue.writeBuffer(gctx.lookupResource(vertex_buffer).?, 0, Vertex, vertex_data[0..]);

    // Create an index buffer.
    const index_buffer = gctx.createBuffer(.{
        .usage = .{ .copy_dst = true, .index = true },
        .size = 3 * @sizeOf(u32),
    });
    const index_data = [_]u32{ 0, 1, 2 };
    gctx.queue.writeBuffer(gctx.lookupResource(index_buffer).?, 0, u32, index_data[0..]);

    // Create a depth texture and its 'view'.
    const depth = createDepthTexture(gctx);
    gpuMesh = GpuMesh{
        .gctx = gctx,
        .pipeline = pipeline,
        .bind_group = bind_group,
        .vertex_buffer = vertex_buffer,
        .index_buffer = index_buffer,
        .depth_texture = depth.texture,
        .depth_texture_view = depth.view,
    };
}
fn on_draw(appBackend: *backend.AppBackend) void {
    const gctx = appBackend.gctx;

    zgui.backend.newFrame(
        gctx.swapchain_descriptor.width,
        gctx.swapchain_descriptor.height,
    );
    zgui.showDemoWindow(null);

    const fb_width = gctx.swapchain_descriptor.width;
    const fb_height = gctx.swapchain_descriptor.height;
    const t = @as(f32, @floatCast(gctx.stats.time));

    const cam_world_to_view = Mat4.lookAt(
        Vec3.new(3.0, 3.0, -3.0),
        Vec3.new(0.0, 0.0, 0.0),
        Vec3.new(0.0, 1.0, 0.0),
    );
    const cam_view_to_clip = Mat4.perspective(
        math.pi / 3.0,
        @as(f32, @floatFromInt(fb_width)) / @as(f32, @floatFromInt(fb_height)),
        0.01,
        200.0,
    );
    const cam_world_to_clip = cam_view_to_clip.mul(&cam_world_to_view);

    const back_buffer_view = gctx.swapchain.getCurrentTextureView();
    defer back_buffer_view.release();

    const commands = commands: {
        const encoder = gctx.device.createCommandEncoder(null);
        defer encoder.release();

        pass: {
            const vb_info = gctx.lookupResourceInfo(gpuMesh.vertex_buffer) orelse break :pass;
            const ib_info = gctx.lookupResourceInfo(gpuMesh.index_buffer) orelse break :pass;
            const pipeline = gctx.lookupResource(gpuMesh.pipeline) orelse break :pass;
            const bind_group = gctx.lookupResource(gpuMesh.bind_group) orelse break :pass;
            const depth_view = gctx.lookupResource(gpuMesh.depth_texture_view) orelse break :pass;

            const color_attachments = [_]wgpu.RenderPassColorAttachment{.{
                .view = back_buffer_view,
                .load_op = .clear,
                .store_op = .store,
            }};
            const depth_attachment = wgpu.RenderPassDepthStencilAttachment{
                .view = depth_view,
                .depth_load_op = .clear,
                .depth_store_op = .store,
                .depth_clear_value = 1.0,
            };
            const render_pass_info = wgpu.RenderPassDescriptor{
                .color_attachment_count = color_attachments.len,
                .color_attachments = &color_attachments,
                .depth_stencil_attachment = &depth_attachment,
            };
            const pass = encoder.beginRenderPass(render_pass_info);
            defer {
                pass.end();
                pass.release();
            }

            pass.setVertexBuffer(0, vb_info.gpuobj.?, 0, vb_info.size);
            pass.setIndexBuffer(ib_info.gpuobj.?, .uint32, 0, ib_info.size);

            pass.setPipeline(pipeline);

            // Draw triangle 1.
            {
                const object_to_world = Mat4.translate(Vec3.new(-1.0, 0.0, 0.0)).mul(&Mat4.rotateY(t));
                const object_to_clip = cam_world_to_clip.mul(&object_to_world);
                const mem = gctx.uniformsAllocate(Mat4, 1);
                mem.slice[0] = object_to_clip;
                pass.setBindGroup(0, bind_group, &.{mem.offset});
                pass.drawIndexed(3, 1, 0, 0, 0);
            }

            {
                const object_to_world = Mat4.translate(Vec3.new(1.0, 0.0, 0.0)).mul(&Mat4.rotateY(t * 0.75));
                const object_to_clip = cam_world_to_clip.mul(&object_to_world);
                const mem = gctx.uniformsAllocate(Mat4, 1);
                mem.slice[0] = object_to_clip;
                pass.setBindGroup(0, bind_group, &.{mem.offset});
                pass.drawIndexed(3, 1, 0, 0, 0);
            }
        }
        {
            const color_attachments = [_]wgpu.RenderPassColorAttachment{.{
                .view = back_buffer_view,
                .load_op = .load,
                .store_op = .store,
            }};
            const render_pass_info = wgpu.RenderPassDescriptor{
                .color_attachment_count = color_attachments.len,
                .color_attachments = &color_attachments,
            };
            const pass = encoder.beginRenderPass(render_pass_info);
            defer {
                pass.end();
                pass.release();
            }

            zgui.backend.draw(pass);
        }
        break :commands encoder.finish(null);
    };
    defer commands.release();

    gctx.submit(&.{commands});

    if (gctx.present() == .swap_chain_resized) {
        // Release old depth texture.
        gctx.releaseResource(gpuMesh.depth_texture_view);
        gctx.destroyResource(gpuMesh.depth_texture);

        // Create a new depth texture to match the new window size.
        const depth = createDepthTexture(gctx);
        gpuMesh.depth_texture = depth.texture;
        gpuMesh.depth_texture_view = depth.view;
    }
}
fn on_deinit() !void {}

pub fn module() modules.Module {
    const meshes = modules.Module{
        .name = "meshes",
        .draw_fn = on_draw,
        .init_fn = on_init,
        .cleanup_fn = on_deinit,
    };
    return meshes;
}

fn createDepthTexture(gctx: *zgpu.GraphicsContext) struct {
    texture: zgpu.TextureHandle,
    view: zgpu.TextureViewHandle,
} {
    const texture = gctx.createTexture(.{
        .usage = .{ .render_attachment = true },
        .dimension = .tdim_2d,
        .size = .{
            .width = gctx.swapchain_descriptor.width,
            .height = gctx.swapchain_descriptor.height,
            .depth_or_array_layers = 1,
        },
        .format = .depth32_float,
        .mip_level_count = 1,
        .sample_count = 1,
    });
    const view = gctx.createTextureView(texture, .{});
    return .{ .texture = texture, .view = view };
}

fn mat4ToGpuMat4(mat4: *const Mat4) [16]f32 {
    const v = mat4.toArray();
    var res: [16]f32 = [1]f32{0} ** 16;
    for (v, 0..) |vv, i| {
        res[i] = @floatCast(@round(vv));
    }
    return res;
}
