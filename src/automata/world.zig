const std = @import("std");
const rl = @import("raylib");
const tp = @import("../misc/types.zig");
const Kernel = @import("./kernel.zig").Kernel;

pub const BUFFER_TYPE = enum {
    MAIN_BUFFER,
    BACKGROUND_BUFFER,
};

pub fn World(comptime T: type, comptime WORLD_WIDTH: comptime_int, comptime WORLD_HEIGHT: comptime_int) type {
    return struct {
        // config
        // width: usize = WORLD_WIDTH,
        // height: usize = WORLD_HEIGHT,
        
        // state
        // buffers
        main_buff: [WORLD_WIDTH][WORLD_HEIGHT]T,
        bg_buff: [WORLD_WIDTH][WORLD_HEIGHT]T,
        current_buffer: BUFFER_TYPE = .MAIN_BUFFER,

        const Self = @This();

        pub fn init(
            default_value: T, 
        ) Self {
            var main_buff = std.mem.zeroes([WORLD_WIDTH][WORLD_HEIGHT]T);
            var bg_buff = std.mem.zeroes([WORLD_WIDTH][WORLD_HEIGHT]T);
            for (0..WORLD_HEIGHT) |y| {
                for (0..WORLD_WIDTH) |x| {
                    main_buff[x][y] = default_value;
                    bg_buff[x][y] = default_value;
                }
            }

            return Self{
                .main_buff = main_buff,
                .bg_buff = bg_buff,
            };
        }

        pub fn getMainV(self: *const Self, wld_pos: tp.Vec2i) T {
            const x = @as(usize, @intCast(@mod(wld_pos.x, WORLD_WIDTH)));
            const y = @as(usize, @intCast(@mod(wld_pos.y, WORLD_HEIGHT)));

            return self.main_buff[x][y];
        }

        pub fn getMain(self: *const Self, x: usize, y: usize) T {
            return self.main_buff[x][y];
        }

        pub fn setMainV(self: *Self, wld_pos: tp.Vec2i, value: T) void {
            const x = @as(usize, @intCast(@mod(wld_pos.x, WORLD_WIDTH)));
            const y = @as(usize, @intCast(@mod(wld_pos.y, WORLD_HEIGHT)));

            self.main_buff[x][y] = value;
        }

        pub fn setMain(self: *Self, x: usize, y: usize, value: T) void {
            self.main_buff[x][y] = value;
        }

        pub fn getBgV(self: *const Self, wld_pos: tp.Vec2i) T {
            const x = @as(usize, @intCast(@mod(wld_pos.x, WORLD_WIDTH)));
            const y = @as(usize, @intCast(@mod(wld_pos.y, WORLD_HEIGHT)));

            return self.bg_buff[x][y];
        }

        pub fn getBg(self: *const Self, x: usize, y: usize) T {
            return self.bg_buff[x][y];
        }

        pub fn setBgV(self: *Self, wld_pos: tp.Vec2i, value: T) void {
            const x = @as(usize, @intCast(@mod(wld_pos.x, WORLD_WIDTH)));
            const y = @as(usize, @intCast(@mod(wld_pos.y, WORLD_HEIGHT)));

            self.bg_buff[x][y] = value;
        }

        pub fn setBg(self: *Self, x: usize, y: usize, value: T) void {
            self.bg_buff[x][y] = value;
        }

        pub fn swapBuffers(self: *Self) void {
            const tmp = self.main_buff;
            self.main_buff = self.bg_buff;
            self.bg_buff = tmp;
        }
    };
}
