const std = @import("std");
const testing = std.testing;

const vec = @import("vec.zig");
const mat = @import("mat.zig");
const q = @import("quat.zig");
const ray = @import("ray.zig");
const h = @import("hpr.zig");
pub usingnamespace @import("epsilon.zig");

/// Public namespaces
pub const collision = @import("collision.zig");

/// Standard f32 precision types
pub const Vec2 = vec.Vec2(f32);
pub const Vec3 = vec.Vec3(f32);
pub const Vec4 = vec.Vec4(f32);
pub const Quat = q.Quat(f32);
pub const Mat2x2 = mat.Mat2x2(f32);
pub const Mat3x3 = mat.Mat3x3(f32);
pub const Mat4x4 = mat.Mat4x4(f32);
pub const Ray = ray.Ray3(f32);
pub const HeadingPitchRoll = h.HeadingPitchRoll(f32);

/// Half-precision f16 types
pub const Vec2h = vec.Vec2(f16);
pub const Vec3h = vec.Vec3(f16);
pub const Vec4h = vec.Vec4(f16);
pub const Quath = q.Quat(f16);
pub const Mat2x2h = mat.Mat2x2(f16);
pub const Mat3x3h = mat.Mat3x3(f16);
pub const Mat4x4h = mat.Mat4x4(f16);
pub const Rayh = ray.Ray3(f16);
pub const HeadingPitchRollh = h.HeadingPitchRoll(f16);

/// Double-precision f64 types
pub const Vec2d = vec.Vec2(f64);
pub const Vec3d = vec.Vec3(f64);
pub const Vec4d = vec.Vec4(f64);
pub const Quatd = q.Quat(f64);
pub const Mat2x2d = mat.Mat2x2(f64);
pub const Mat3x3d = mat.Mat3x3(f64);
pub const Mat4x4d = mat.Mat4x4(f64);
pub const Rayd = ray.Ray3(f64);
pub const HeadingPitchRolld = h.HeadingPitchRoll(f64);

/// Standard f32 precision initializers
pub const vec2 = Vec2.init;
pub const vec3 = Vec3.init;
pub const vec4 = Vec4.init;
pub const vec2FromInt = Vec2.fromInt;
pub const vec3FromInt = Vec3.fromInt;
pub const vec4FromInt = Vec4.fromInt;
pub const quat = Quat.init;
pub const mat2x2 = Mat2x2.init;
pub const mat3x3 = Mat3x3.init;
pub const mat4x4 = Mat4x4.init;
pub const hpr = HeadingPitchRoll.init;

/// Half-precision f16 initializers
pub const vec2h = Vec2h.init;
pub const vec3h = Vec3h.init;
pub const vec4h = Vec4h.init;
pub const vec2hFromInt = Vec2h.fromInt;
pub const vec3hFromInt = Vec3h.fromInt;
pub const vec4hFromInt = Vec4h.fromInt;
pub const quath = Quath.init;
pub const mat2x2h = Mat2x2h.init;
pub const mat3x3h = Mat3x3h.init;
pub const mat4x4h = Mat4x4h.init;
pub const hprh = HeadingPitchRollh.init;

/// Double-precision f64 initializers
pub const vec2d = Vec2d.init;
pub const vec3d = Vec3d.init;
pub const vec4d = Vec4d.init;
pub const vec2dFromInt = Vec2d.fromInt;
pub const vec3dFromInt = Vec3d.fromInt;
pub const vec4dFromInt = Vec4d.fromInt;
pub const quatd = Quatd.init;
pub const mat2x2d = Mat2x2d.init;
pub const mat3x3d = Mat3x3d.init;
pub const mat4x4d = Mat4x4d.init;
pub const hprd = HeadingPitchRolld.init;

test {
    testing.refAllDeclsRecursive(@This());
}

// std.math customizations
pub const eql = std.math.approxEqAbs;
pub const eps = std.math.floatEps;
pub const eps_f16 = std.math.floatEps(f16);
pub const eps_f32 = std.math.floatEps(f32);
pub const eps_f64 = std.math.floatEps(f64);
pub const nan_f16 = std.math.nan(f16);
pub const nan_f32 = std.math.nan(f32);
pub const nan_f64 = std.math.nan(f64);

// std.math 1:1 re-exports below here
//
// Having two 'math' imports in your code is annoying, so we in general expect that people will not
// need to do this and instead can just import mach.math - we add to this list of re-exports as
// needed.

pub const inf = std.math.inf;
pub const sqrt = std.math.sqrt;
pub const pow = std.math.pow;
pub const sin = std.math.sin;
pub const cos = std.math.cos;
pub const acos = std.math.acos;
pub const isNan = std.math.isNan;
pub const isInf = std.math.isInf;
pub const clamp = std.math.clamp;
pub const log10 = std.math.log10;
pub const degreesToRadians = std.math.degreesToRadians;
pub const radiansToDegrees = std.math.radiansToDegrees;
pub const maxInt = std.math.maxInt;
pub const lerp = std.math.lerp;

pub const rad_per_deg = std.math.rad_per_deg;
pub const deg_per_rad = std.math.deg_per_rad;

pub const pi = std.math.pi;

/// 2 * pi
pub const tau = std.math.tau;

/// 2/sqrt(π)
pub const two_sqrtpi = std.math.two_sqrtpi;

/// sqrt(2)
pub const sqrt2 = std.math.sqrt2;

/// 1/sqrt(2)
pub const sqrt1_2 = std.math.sqrt1_2;

pub fn asinClamped(value: anytype) @TypeOf(value) {
    return std.math.asin(std.math.clamp(value, -1.0, 1.0));
}
