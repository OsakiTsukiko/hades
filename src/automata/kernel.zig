const std = @import("std");
const tp = @import("../misc/types.zig");
const PPMImage = @import("../misc/ppm.zig").PPMImage;

pub const Kernel = struct {
    allocator: std.mem.Allocator,
    mask_list: std.ArrayList(tp.Vec2i),

    pub fn init(allocator: std.mem.Allocator) Kernel {
        return Kernel {
            .allocator = allocator,
            .mask_list = std.ArrayList(tp.Vec2i).init(allocator),
        };
    }

    pub fn append(self: *Kernel, val: tp.Vec2i) void {
        self.mask_list.append(val) catch unreachable;
    }

    pub fn deinit(self: *Kernel) void {
        self.mask_list.deinit();
    }

    pub fn fromPPM(self: *Kernel, img: *PPMImage) void {
        var offset = tp.Vec2i.new(img.width, img.height);
        offset.div(2);
        std.debug.print("offset: {d} {d}\n", .{offset.x, offset.y});
        for (0..@as(usize, @intCast(img.height))) |y| {
            for (0..@as(usize, @intCast(img.width))) |x| {
                const v = tp.Vec2i.fromUsize(x, y).subvn(offset);
                // if (v.x == 0 and v.y == 0) continue;
                if (img.buffer[x][y].r == 255) {
                    self.mask_list.append(v) catch unreachable;
                }
            }
        }
    }
};