const lib = @import("../lib.zig");
const wgpu = lib.wgpu;
const zgpu = lib.zgpu;
const math = @import("math");
const Mat4 = math.Mat4x4;
const Vec3 = math.Vec3;
const Quat = math.Quat;
const mesh = @import("./index.zig");
const Geometry = mesh.Geometry;
const Material = mesh.Material;
const Context = mesh.Context;
pub const MeshUniforms = struct {
    model: Mat4,
    view: Mat4,
    projection: Mat4,
    pub fn new() MeshUniforms {
        return .{
            .model = Mat4.identity(),
            .view = Mat4.identity(),
            .projection = Mat4.identity(),
        };
    }
};
const State = struct {
    pipeline: zgpu.RenderPipelineHandle,
    mesh_uniforms_bg: zgpu.BindGroupHandle,
};
const Self = @This();
geometry: Geometry,
material: Material,
state: State = undefined,
is_upload: bool = false,
matrix: Mat4 = Mat4.identity(),
matrixWorld: Mat4 = Mat4.identity(),
parent: ?*Self = null,
children: lib.ArrayList(*Self),
// mesh_uniforms: MeshUniforms,
pub fn new(geometry: Geometry, material: Material) Self {
    return .{
        .geometry = geometry,
        .material = material,
        .children = lib.ArrayList(*Self).init(lib.mem.getAllocator()),
    };
}
pub fn deinit(self: *Self) void {
    self.geometry.deinit();
    self.material.deinit();
    self.removeAll();
    self.children.deinit();
}
pub fn upload(self: *Self, ctx: *Context) void {
    if (self.is_upload) return;
    self.material.upload(ctx.gctx);
    self.geometry.upload(ctx.gctx);
    self.createRenderPipeline(ctx);
    self.is_upload = true;
    for (self.children.items) |children| {
        children.upload(ctx);
    }
}
pub fn updateMatrixWorld(self: *Self) void {
    if (self.parent) |parent| {
        self.matrixWorld = parent.matrixWorld.mul(self.matrix);
    } else {
        self.matrixWorld = self.matrix.clone();
    }
    for (self.children.items) |children| {
        children.updateMatrixWorld();
    }
}
pub fn add(self: *Self, meshv: *Self) void {
    if (self == meshv) {
        @compileError("mesh can't be added as a child of itself.");
    }
    meshv.removeFromParent();
    meshv.parent = self;
    self.children.append(meshv);
}
pub fn remove(self: *Self, meshv: *Self) void {
    var targetIndex: usize = -1;
    for (self.children.items, 0..) |children, i| {
        if (children == meshv) {
            targetIndex = i;
            break;
        }
    }
    if (targetIndex != -1) {
        const children = self.children.swapRemove(targetIndex);
        children.parent = null;
    }
}
pub fn removeFromParent(self: *Self) void {
    if (self.parent) |parent| {
        parent.remove(self);
    }
}
pub fn removeAll(self: *Self) void {
    for (self.children.items) |children| {
        children.parent = null;
    }
    self.children.clearAndFree();
}
fn createRenderPipeline(self: *Self, ctx: *Context) void {
    //create pipeline layout
    var gctx = ctx.gctx;
    const mesh_uniforms_bg_layout = gctx.createBindGroupLayout(&.{
        zgpu.bufferEntry(0, .{ .vertex = true, .fragment = true }, .uniform, true, 0),
    });
    const mesh_uniforms_bg = gctx.createBindGroup(mesh_uniforms_bg_layout, &.{
        .{ .binding = 0, .buffer_handle = gctx.uniforms.buffer, .offset = 0, .size = @sizeOf(MeshUniforms) },
    });
    defer gctx.releaseResource(mesh_uniforms_bg_layout);
    defer gctx.releaseResource(self.material.uniform.layout);

    const pipeline_layout = gctx.createPipelineLayout(&.{ mesh_uniforms_bg_layout, self.material.uniform.layout });
    defer gctx.releaseResource(pipeline_layout);

    const vertexBufferLayouts = [_]wgpu.VertexBufferLayout{
        self.geometry.vertexBufferLayout(),
    };

    const color_targets = [_]wgpu.ColorTargetState{.{
        .format = zgpu.GraphicsContext.swapchain_format,
    }};
    const desc = wgpu.RenderPipelineDescriptor{
        .vertex = wgpu.VertexState{
            .module = self.material.vs_module,
            .entry_point = "vsMain",
            .buffer_count = vertexBufferLayouts.len,
            .buffers = &vertexBufferLayouts,
        },
        .primitive = wgpu.PrimitiveState{
            .front_face = .ccw,
            .cull_mode = .none,
            .topology = self.geometry.primitiveTopology,
        },
        .depth_stencil = &wgpu.DepthStencilState{
            .format = .depth32_float,
            .depth_write_enabled = true,
            .depth_compare = .less,
        },
        .fragment = &wgpu.FragmentState{
            .module = self.material.fs_module,
            .entry_point = "fsMain",
            .target_count = color_targets.len,
            .targets = &color_targets,
        },
    };
    //create pipeline
    const pipeline = gctx.createRenderPipeline(pipeline_layout, desc);

    self.state = .{ .mesh_uniforms_bg = mesh_uniforms_bg, .pipeline = pipeline };
}
pub fn draw(self: *Self, ctx: *Context) void {
    var gctx = ctx.gctx;
    const pass = ctx.pass;
    const vb_info = gctx.lookupResourceInfo(self.geometry.vertex_buffer).?;
    const ib_info = gctx.lookupResourceInfo(self.geometry.index_buffer).?;
    const mesh_uniforms_bg = gctx.lookupResource(self.state.mesh_uniforms_bg).?;
    const material_uniforms_bg = gctx.lookupResource(self.material.uniform.bind_group).?;
    const pipeline = gctx.lookupResource(self.state.pipeline).?;
    pass.setVertexBuffer(0, vb_info.gpuobj.?, 0, self.geometry.vertex_data.len);
    pass.setIndexBuffer(ib_info.gpuobj.?, .uint32, 0, ib_info.size);
    pass.setPipeline(pipeline);
    {
        const mem0 = gctx.uniformsAllocate(MeshUniforms, 1);
        // const t = @as(f32, @floatCast(gctx.stats.time));
        // const model = Mat4.translate(Vec3.new(-1.0, 0.0, 0.0)).mul(&Mat4.rotateY(t));
        mem0.slice[0] = .{
            .model = self.matrixWorld,
            .view = ctx.view,
            .projection = ctx.projection,
        };
        pass.setBindGroup(0, mesh_uniforms_bg, &.{mem0.offset});
        pass.setBindGroup(1, material_uniforms_bg, &.{self.material.uniform.write_uniform(ctx)});
        pass.drawIndexed(3, 1, 0, 0, 0);
    }
    for (self.children.items) |children| {
        children.draw(ctx);
    }
}
