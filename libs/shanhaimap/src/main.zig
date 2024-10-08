const std = @import("std");
const lib = @import("root.zig");
const testing = @import("std").testing;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var mapviwe = try lib.MapView.init(allocator);
    defer mapviwe.deinit();
}
test "main" {}
