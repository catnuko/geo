const std = @import("std");
const stdmath = std.math;
const print = std.debug.print;
const testing = std.testing;
const Box3 = @import("./box3.zig").Box3;
const Vec3 = @import("./math/generic_vector.zig").Vec3;
const GeoCoordinates = @import("./geo_coordinates.zig").GeoCoordinates;
const earth = @import("./earth.zig");

pub const ProjectionType = enum { Planar, Spherical };
/// convert geo coordinate to world point
pub fn project(geopoint: GeoCoordinates, unit_scale: f64) Vec3 {
    const radius = unit_scale + (geopoint.altitude orelse 0);
    const latitude = stdmath.degreesToRadians(geopoint.latitude);
    const longitude = stdmath.degreesToRadians(geopoint.longitude);
    const cosLatitude = stdmath.cos(latitude);
    return Vec3.new(radius * cosLatitude * stdmath.cos(longitude), radius * cosLatitude * stdmath.sin(longitude), radius * stdmath.sin(latitude));
}
pub const SphereProjection = struct {
    unit_scale: f64,
    pub fn new(unit_scale: f64) SphereProjection {
        return .{ .unit_scale = unit_scale };
    }
    pub fn world_extent(
        self: SphereProjection,
        max_elevation: f64,
    ) Box3 {
        const radius = self.unit_scale + max_elevation;
        Box3.new(Vec3.new(
            -radius,
            -radius,
            -radius,
        ), Vec3.new(
            radius,
            radius,
            radius,
        ));
    }
    pub fn project_point(self: SphereProjection, geopoint: GeoCoordinates) Vec3 {
        return project(geopoint, self.unit_scale);
    }
    pub fn unproject_point(self: SphereProjection, worldpoint: Vec3) GeoCoordinates {
        const parallelRadiusSq = worldpoint.x() * worldpoint.x() + worldpoint.y() * worldpoint.y();
        const parallelRadius = stdmath.sqrt(parallelRadiusSq);
        const v = worldpoint.z() / parallelRadius;

        if (stdmath.isNan(v)) {
            return GeoCoordinates.from_radians(0, 0, -self.unit_scale);
        }
        const radius = stdmath.sqrt(parallelRadiusSq + worldpoint.z() * worldpoint.z());
        return GeoCoordinates.from_radians(stdmath.atan2(worldpoint.y(), worldpoint.x()), stdmath.atan(v), radius - self.unit_scale);
    }
    pub fn unproject_altitude(_: SphereProjection, worldpoint: Vec3) f64 {
        return worldpoint.length() - earth.EQUATORIAL_RADIUS;
    }
    pub fn ground_distance(self: SphereProjection, worldpoint: Vec3) f64 {
        return worldpoint.length() - self.unit_scale;
    }
    pub fn scale_point_to_surface(self: SphereProjection, worldpoint: Vec3) Vec3 {
        var length = worldpoint.length();
        if (length == 0) {
            length = 1.0;
        }
        const scale = self.unit_scale / length;
        return worldpoint.scale(scale);
    }
};
pub const sphereProjection = SphereProjection.new(earth.EQUATORIAL_RADIUS);
test "projection.shpere_projection.project_and_unproject" {
    const geoPoint = GeoCoordinates.from_degrees(-122.4410209359072, 37.8178183439856, 12.0);
    try testing.expectEqual(geoPoint.longitude, -122.4410209359072);
    const epsilon = 0.000000001;
    const worldPoint = sphereProjection.project_point(geoPoint);
    const geoPoint2 = sphereProjection.unproject_point(worldPoint);
    try testing.expectApproxEqAbs(geoPoint.latitude, geoPoint2.latitude, epsilon);
    try testing.expectApproxEqAbs(geoPoint.longitude, geoPoint2.longitude, epsilon);
    try testing.expectApproxEqAbs(geoPoint.altitude.?, geoPoint2.altitude.?, epsilon);
}

test "projection.shpere_projection.ground_distance" {
    const geoPoint = GeoCoordinates.from_degrees(-122.4410209359072, 37.8178183439856, 12.0);
    const epsilon = 0.000000001;
    const worldPoint = sphereProjection.project_point(geoPoint);
    try testing.expectApproxEqAbs(sphereProjection.ground_distance(worldPoint), 12, epsilon);
}

test "projection.shpere_projection.scale_point_to_surface" {
    const geoPoint = GeoCoordinates.from_degrees(-122.4410209359072, 37.8178183439856, 12.0);
    const epsilon = 0.000000001;
    const worldPoint = sphereProjection.project_point(geoPoint);
    const worldPoint2 = sphereProjection.scale_point_to_surface(worldPoint);
    try testing.expectApproxEqAbs(sphereProjection.ground_distance(worldPoint2), 0, epsilon);
}
