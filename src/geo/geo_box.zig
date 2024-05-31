const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const coord = @import("lng_lat_alt.zig");
const LngLatAlt = coord.LngLatAlt;
const MAX_LONGITUDE = coord.MAX_LONGITUDE;
pub const GeoBox = struct {
    southWest: LngLatAlt,
    northEast: LngLatAlt,
    pub fn new(
        southWest: LngLatAlt,
        northEast: LngLatAlt,
    ) GeoBox {
        var news = GeoBox{
            .southWest = southWest,
            .northEast = northEast,
        };
        if (news.west() > news.east()) {
            news.northEast.longitude += 360;
        }
        return news;
    }
    pub fn from_center_and_extents(center_v: LngLatAlt, extents: GeoBox) GeoBox {
        return GeoBox.new(
            LngLatAlt.from_degrees(
                center_v.longitude - extents.longitude_span() / 2,
                center_v.latitude - extents.latitude_span() / 2,
            ),
            LngLatAlt.from_degrees(
                center_v.longitude + extents.longitude_span() / 2,
                center_v.latitude + extents.latitude_span() / 2,
            ),
        );
    }
    pub inline fn min_altitude(self: GeoBox) ?f64 {
        if (self.southWest.altitude == null or self.northEast.altitude == null) {
            return null;
        }
        return @min(self.southWest.altitude.?, self.northEast.altitude.?);
    }
    pub inline fn max_altitude(self: GeoBox) ?f64 {
        if (self.southWest.altitude == null or self.northEast.altitude == null) {
            return null;
        }
        return @max(self.southWest.altitude.?, self.northEast.altitude.?);
    }
    pub inline fn south(self: GeoBox) f64 {
        return self.southWest.latitude;
    }
    pub inline fn north(self: GeoBox) f64 {
        return self.northEast.latitude;
    }
    pub inline fn west(self: GeoBox) f64 {
        return self.southWest.longitude;
    }
    pub inline fn east(self: GeoBox) f64 {
        return self.northEast.longitude;
    }
    fn get_altitude_helper(self: GeoBox) ?f64 {
        const min_altitude_v = self.min_altitude();
        const altitude_span_v = self.altitude_span();
        if (min_altitude_v != null and altitude_span_v != null) {
            const a = min_altitude_v.?;
            const b = altitude_span_v.?;
            return a + b * 0.5;
        } else {
            return null;
        }
    }
    pub fn center(self: GeoBox) LngLatAlt {
        const east_v = self.east();
        const west_v = self.west();
        const north_v = self.north();
        const south_v = self.south();
        const latitude_v = (south_v + north_v) * 0.5;
        const altitude_v = self.get_altitude_helper();
        if (west_v <= east_v) {
            return LngLatAlt.from_degrees((west_v + east_v) * 0.5, latitude_v, altitude_v);
        }
        var longitude_v = (360 + east_v + west_v) * 0.5;

        if (longitude_v > 360) {
            longitude_v -= 360;
        }
        return LngLatAlt.from_degrees(longitude_v, latitude_v, altitude_v);
    }
    pub inline fn latitude_span(self: GeoBox) f64 {
        return self.north() - self.south();
    }
    pub inline fn altitude_span(self: GeoBox) ?f64 {
        const max_altitude_v = self.max_altitude();
        const min_altitude_v = self.min_altitude();
        if (max_altitude_v == null or min_altitude_v == null) {
            return null;
        }
        return max_altitude_v.? - min_altitude_v.?;
    }
    pub inline fn longitude_span(self: GeoBox) f64 {
        var width = self.east() - self.west();
        if (width < 0.0) {
            width += 360;
        }
        return width;
    }
    pub inline fn clone(self: GeoBox) GeoBox {
        return GeoBox.new(self.southWest, self.northEast);
    }
    pub fn contains(self: GeoBox, point: LngLatAlt) bool {
        const min_altitude_v = self.min_altitude();
        const max_altitude_v = self.max_altitude();
        if (point.altitude == null or min_altitude_v == null or max_altitude_v == null) {
            return self.contains_helper(point);
        }
        const min_altitude_h = min_altitude_v.?;
        const max_altitude_h = max_altitude_v.?;
        const point_altitude = point.altitude.?;
        const isFlat = min_altitude_h == max_altitude_h;
        const isSameAltitude = min_altitude_h == point_altitude;
        const isWithinAltitudeRange =
            min_altitude_h <= point_altitude and max_altitude_h > point_altitude;

        if (if (isFlat) isSameAltitude else isWithinAltitudeRange) {
            return self.contains_helper(point);
        }
        return false;
    }
    pub fn contains_helper(self: GeoBox, point: LngLatAlt) bool {
        if (point.latitude < self.southWest.latitude or point.latitude >= self.northEast.latitude) {
            return false;
        }
        const east_v: f64 = self.east();
        const west_v: f64 = self.west();

        var longitude = point.longitude;
        if (east_v > MAX_LONGITUDE) {
            while (longitude < west_v) {
                longitude = longitude + 360;
            }
        }

        if (longitude > east_v) {
            while (longitude > west_v + 360) {
                longitude = longitude - 360;
            }
        }

        return longitude >= west_v and longitude < east_v;
    }
    pub fn grow_to_contain(self: *GeoBox, point: LngLatAlt) void {
        self.southWest.latitude = @min(self.southWest.latitude, point.latitude);
        self.southWest.longitude = @min(self.southWest.longitude, point.longitude);
        self.southWest.altitude = {
            if (self.southWest.altitude != null and point.altitude != null) {
                @min(self.southWest.altitude, point.altitude);
            } else if (self.southWest.altitude != null) {
                self.southWest.altitude;
            } else if (point.altitude != null) {
                point.altitude;
            } else {
                null;
            }
        };
        self.northEast.latitude = @max(self.northEast.latitude, point.latitude);
        self.northEast.longitude = @max(self.northEast.longitude, point.longitude);
        self.northEast.altitude = {
            if (self.northEast.altitude != null and point.altitude != null) {
                @max(self.northEast.altitude, point.altitude);
            } else if (self.northEast.altitude != null) {
                self.northEast.altitude;
            } else if (point.altitude != null) {
                point.altitude;
            } else {
                null;
            }
        };
    }
};

const GEOCOORDS_EPSILON = 0.000001;
test "geo.geo.geo_box.center" {
    const g = GeoBox.new(LngLatAlt.from_degrees(170, -10, null), LngLatAlt.from_degrees(-160, 10, null));
    try testing.expectEqual(g.west(), 170);
    try testing.expectEqual(g.east(), 200);
    try testing.expectEqual(g.north(), 10);
    try testing.expectEqual(g.south(), -10);
    const center = g.center();
    try testing.expectApproxEqAbs(center.longitude, 185, GEOCOORDS_EPSILON);
    try testing.expectApproxEqAbs(center.latitude, 0, GEOCOORDS_EPSILON);
    try testing.expectApproxEqAbs(g.longitude_span(), 30, GEOCOORDS_EPSILON);
    try testing.expectApproxEqAbs(g.latitude_span(), 20, GEOCOORDS_EPSILON);

    try testing.expect(g.contains(LngLatAlt.from_degrees(180, 0, null)));
    try testing.expect(g.contains(LngLatAlt.from_degrees(190, 0, null)));
    try testing.expect(g.contains(LngLatAlt.from_degrees(-170, 0, null)));
    try testing.expect(g.contains(LngLatAlt.from_degrees(-530, 0, null)));
    try testing.expect(g.contains(LngLatAlt.from_degrees(540, 0, null)));

    try testing.expect(!g.contains(LngLatAlt.from_degrees(
        -159,
        0,
        null,
    )));
    try testing.expect(!g.contains(LngLatAlt.from_degrees(
        201,
        0,
        null,
    )));
    try testing.expect(!g.contains(LngLatAlt.from_degrees(
        561,
        0,
        null,
    )));
    try testing.expect(!g.contains(LngLatAlt.from_degrees(
        -510,
        0,
        null,
    )));
}
