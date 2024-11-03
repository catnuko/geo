const lib = @import("../lib.zig");
const wgpu = lib.wgpu;
const zgpu = lib.zgpu;
const ArrayList = lib.ArrayList;
pub const AttributeData = union(enum) {
    uint8x2: ArrayList([2]u8),
    uint8x4: ArrayList([4]u8),
    sint8x2: ArrayList([2]i8),
    sint8x4: ArrayList([4]i8),
    unorm8x2: ArrayList([2]u8),
    unorm8x4: ArrayList([4]u8),
    snorm8x2: ArrayList([2]i8),
    snorm8x4: ArrayList([4]i8),
    uint16x2: ArrayList([2]u16),
    uint16x4: ArrayList([4]u16),
    sint16x2: ArrayList([2]i16),
    sint16x4: ArrayList([4]i16),
    unorm16x2: ArrayList([2]u16),
    unorm16x4: ArrayList([4]u16),
    snorm16x2: ArrayList([2]i16),
    snorm16x4: ArrayList([4]i16),
    float16x2: ArrayList([2]f16),
    float16x4: ArrayList([4]f16),
    float32: ArrayList(f32),
    float32x2: ArrayList([2]f32),
    float32x3: ArrayList([3]f32),
    float32x4: ArrayList([4]f32),
    uint32: ArrayList(u32),
    uint32x2: ArrayList([2]u32),
    uint32x3: ArrayList([3]u32),
    uint32x4: ArrayList([4]u32),
    sint32: ArrayList(i32),
    sint32x2: ArrayList([2]i32),
    sint32x3: ArrayList([3]i32),
    sint32x4: ArrayList([4]i32),
    pub fn deinit(self: *AttributeData) void {
        switch (self.*) {
            .uint8x2 => |v| v.deinit(),
            .uint8x4 => |v| v.deinit(),
            .sint8x2 => |v| v.deinit(),
            .sint8x4 => |v| v.deinit(),
            .unorm8x2 => |v| v.deinit(),
            .unorm8x4 => |v| v.deinit(),
            .snorm8x2 => |v| v.deinit(),
            .snorm8x4 => |v| v.deinit(),
            .uint16x2 => |v| v.deinit(),
            .uint16x4 => |v| v.deinit(),
            .sint16x2 => |v| v.deinit(),
            .sint16x4 => |v| v.deinit(),
            .unorm16x2 => |v| v.deinit(),
            .unorm16x4 => |v| v.deinit(),
            .snorm16x2 => |v| v.deinit(),
            .snorm16x4 => |v| v.deinit(),
            .float16x2 => |v| v.deinit(),
            .float16x4 => |v| v.deinit(),
            .float32 => |v| v.deinit(),
            .float32x2 => |v| v.deinit(),
            .float32x3 => |v| v.deinit(),
            .float32x4 => |v| v.deinit(),
            .uint32 => |v| v.deinit(),
            .uint32x2 => |v| v.deinit(),
            .uint32x3 => |v| v.deinit(),
            .uint32x4 => |v| v.deinit(),
            .sint32 => |v| v.deinit(),
            .sint32x2 => |v| v.deinit(),
            .sint32x3 => |v| v.deinit(),
            .sint32x4 => |v| v.deinit(),
        }
    }
    pub fn len(self: *const AttributeData) usize {
        return switch (self.*) {
            .uint8x2 => |v| v.items.len,
            .uint8x4 => |v| v.items.len,
            .sint8x2 => |v| v.items.len,
            .sint8x4 => |v| v.items.len,
            .unorm8x2 => |v| v.items.len,
            .unorm8x4 => |v| v.items.len,
            .snorm8x2 => |v| v.items.len,
            .snorm8x4 => |v| v.items.len,
            .uint16x2 => |v| v.items.len,
            .uint16x4 => |v| v.items.len,
            .sint16x2 => |v| v.items.len,
            .sint16x4 => |v| v.items.len,
            .unorm16x2 => |v| v.items.len,
            .unorm16x4 => |v| v.items.len,
            .snorm16x2 => |v| v.items.len,
            .snorm16x4 => |v| v.items.len,
            .float16x2 => |v| v.items.len,
            .float16x4 => |v| v.items.len,
            .float32 => |v| v.items.len,
            .float32x2 => |v| v.items.len,
            .float32x3 => |v| v.items.len,
            .float32x4 => |v| v.items.len,
            .uint32 => |v| v.items.len,
            .uint32x2 => |v| v.items.len,
            .uint32x3 => |v| v.items.len,
            .uint32x4 => |v| v.items.len,
            .sint32 => |v| v.items.len,
            .sint32x2 => |v| v.items.len,
            .sint32x3 => |v| v.items.len,
            .sint32x4 => |v| v.items.len,
        };
    }
};
// pub const Attribute = struct {
//     name: []const u8,
//     shader_location: u32,
//     offset: u64,
//     format: wgpu.VertexFormat,
//     pub fn new(
//         namev: []const u8,
//         shader_location: u32,
//         offset: u64,
//         format: wgpu.VertexFormat,
//     ) Attribute {
//         return .{
//             .name = namev,
//             .shader_location = shader_location,
//             .offset = offset,
//             .format = format,
//         };
//     }
//     pub fn get_attribute(self: *const Attribute) wgpu.VertexAttribute {
//         return wgpu.VertexAttribute{
//             .format = self.format,
//             .shader_location = self.shader_location,
//             .offset = self.offset,
//         };
//     }
//     pub fn getSize(self: *const Attribute) u64 {
//         return sizeOfVertexFormat(self.format);
//     }
// };
pub fn sizeOfVertexFormat(format: wgpu.VertexFormat) u64 {
    return switch (format) {
        .undef => 0,
        .uint8x2 => 2,
        .uint8x4 => 4,
        .sint8x2 => 2,
        .sint8x4 => 4,
        .unorm8x2 => 2,
        .unorm8x4 => 4,
        .snorm8x2 => 2,
        .snorm8x4 => 4,
        .uint16x2 => 4,
        .uint16x4 => 8,
        .sint16x2 => 4,
        .sint16x4 => 8,
        .unorm16x2 => 4,
        .unorm16x4 => 8,
        .snorm16x2 => 4,
        .snorm16x4 => 8,
        .float16x2 => 2,
        .float16x4 => 8,
        .float32 => 4,
        .float32x2 => 8,
        .float32x3 => 12,
        .float32x4 => 16,
        .uint32 => 4,
        .uint32x2 => 8,
        .uint32x3 => 12,
        .uint32x4 => 16,
        .sint32 => 4,
        .sint32x2 => 8,
        .sint32x3 => 12,
        .sint32x4 => 16,
    };
}
// pub const ATTRIBUTE_POSITION: Attribute =
//     Attribute.new("Vertex_Position", 0, 0, wgpu.VertexFormat.float32x3);
// pub const ATTRIBUTE_NORMAL: Attribute =
//     Attribute.new("Vertex_Normal", 1, 0, wgpu.VertexFormat.float32x3);
// pub const ATTRIBUTE_UV_0: Attribute =
//     Attribute.new("Vertex_Uv", 2, 0, wgpu.VertexFormat.float32x2);
// pub const ATTRIBUTE_TANGENT: Attribute =
//     Attribute.new("Vertex_Tangent", 3, 0, wgpu.VertexFormat.float32x4);
// pub const ATTRIBUTE_COLOR: Attribute =
//     Attribute.new("Vertex_Color", 4, 0, wgpu.VertexFormat.float32x4);
// pub const ATTRIBUTE_JOINT_WEIGHT: Attribute =
//     Attribute.new("Vertex_JointWeight", 5, 0, wgpu.VertexFormat.float32x4);
// pub const ATTRIBUTE_JOINT_INDEX: Attribute =
//     Attribute.new("Vertex_JointIndex", 6, 0, wgpu.VertexFormat.uint16x4);

pub const VertexAttribute = struct {
    name: []const u8,
    attribute: wgpu.VertexAttribute,
    data: AttributeData,
    buffer: ?wgpu.Buffer = null,
    buffer_size: ?u64 = null,
    const Self = @This();
    pub fn array_stride(self: *const Self) u64 {
        return sizeOfVertexFormat(self.attribute.format);
    }
    pub fn bind(self: *const Self, pass: wgpu.RenderPassEncoder) void {
        pass.setVertexBuffer(self.attribute.shader_location, self.buffer.?, 0, self.buffer_size.?);
    }
    pub fn upload(self: *Self, gctx: *zgpu.GraphicsContext) void {
        const buffer_size = self.data.len() * self.array_stride();
        const buffer = gctx.device.createBuffer(.{
            .usage = .{ .copy_dst = true, .vertex = true },
            .size = buffer_size,
        });
        self.buffer = buffer;
        self.buffer_size = buffer_size;
        return switch (self.attribute.format) {
            else => unreachable,
            .uint8x2 => gctx.queue.writeBuffer(
                buffer,
                0,
                [2]u8,
                self.data.uint8x2.items,
            ),
            .uint8x4 => gctx.queue.writeBuffer(
                buffer,
                0,
                [4]u8,
                self.data.uint8x4.items,
            ),
            .sint8x2 => gctx.queue.writeBuffer(
                buffer,
                0,
                [2]i8,
                self.data.sint8x2.items,
            ),
            .sint8x4 => gctx.queue.writeBuffer(
                buffer,
                0,
                [4]i8,
                self.data.sint8x4.items,
            ),
            .unorm8x2 => gctx.queue.writeBuffer(
                buffer,
                0,
                [2]u8,
                self.data.unorm8x2.items,
            ),
            .unorm8x4 => gctx.queue.writeBuffer(
                buffer,
                0,
                [4]u8,
                self.data.unorm8x4.items,
            ),
            .snorm8x2 => gctx.queue.writeBuffer(
                buffer,
                0,
                [2]i8,
                self.data.snorm8x2.items,
            ),
            .snorm8x4 => gctx.queue.writeBuffer(
                buffer,
                0,
                [4]i8,
                self.data.snorm8x4.items,
            ),
            .uint16x2 => gctx.queue.writeBuffer(
                buffer,
                0,
                [2]u16,
                self.data.uint16x2.items,
            ),
            .uint16x4 => gctx.queue.writeBuffer(
                buffer,
                0,
                [4]u16,
                self.data.uint16x4.items,
            ),
            .sint16x2 => gctx.queue.writeBuffer(
                buffer,
                0,
                [2]i16,
                self.data.sint16x2.items,
            ),
            .sint16x4 => gctx.queue.writeBuffer(
                buffer,
                0,
                [4]i16,
                self.data.sint16x4.items,
            ),
            .unorm16x2 => gctx.queue.writeBuffer(
                buffer,
                0,
                [2]u16,
                self.data.unorm16x2.items,
            ),
            .unorm16x4 => gctx.queue.writeBuffer(
                buffer,
                0,
                [4]u16,
                self.data.unorm16x4.items,
            ),
            .snorm16x2 => gctx.queue.writeBuffer(
                buffer,
                0,
                [2]i16,
                self.data.snorm16x2.items,
            ),
            .snorm16x4 => gctx.queue.writeBuffer(
                buffer,
                0,
                [4]i16,
                self.data.snorm16x4.items,
            ),
            .float16x2 => gctx.queue.writeBuffer(
                buffer,
                0,
                [2]f16,
                self.data.float16x2.items,
            ),
            .float16x4 => gctx.queue.writeBuffer(
                buffer,
                0,
                [4]f16,
                self.data.float16x4.items,
            ),
            .float32 => gctx.queue.writeBuffer(
                buffer,
                0,
                f32,
                self.data.float32.items,
            ),
            .float32x2 => gctx.queue.writeBuffer(
                buffer,
                0,
                [2]f32,
                self.data.float32x2.items,
            ),
            .float32x3 => gctx.queue.writeBuffer(
                buffer,
                0,
                [3]f32,
                self.data.float32x3.items,
            ),
            .float32x4 => gctx.queue.writeBuffer(
                buffer,
                0,
                [4]f32,
                self.data.float32x4.items,
            ),
            .uint32 => gctx.queue.writeBuffer(
                buffer,
                0,
                u32,
                self.data.uint32.items,
            ),
            .uint32x2 => gctx.queue.writeBuffer(
                buffer,
                0,
                [2]u32,
                self.data.uint32x2.items,
            ),
            .uint32x3 => gctx.queue.writeBuffer(
                buffer,
                0,
                [3]u32,
                self.data.uint32x3.items,
            ),
            .uint32x4 => gctx.queue.writeBuffer(
                buffer,
                0,
                [4]u32,
                self.data.uint32x4.items,
            ),
            .sint32 => gctx.queue.writeBuffer(
                buffer,
                0,
                i32,
                self.data.sint32.items,
            ),
            .sint32x2 => gctx.queue.writeBuffer(
                buffer,
                0,
                [2]i32,
                self.data.sint32x2.items,
            ),
            .sint32x3 => gctx.queue.writeBuffer(
                buffer,
                0,
                [3]i32,
                self.data.sint32x3.items,
            ),
            .sint32x4 => gctx.queue.writeBuffer(
                buffer,
                0,
                [4]i32,
                self.data.sint32x4.items,
            ),
        };
    }
};
