const std = @import("std");
const fs = std.fs;

pub const RGBAColor = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

pub const PPMImage = struct {
    file: fs.File,
    buffer: [][]RGBAColor = undefined,
    width: i32 = undefined,
    height: i32 = undefined,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, file: fs.File) PPMImage {
        return PPMImage {
            .file = file,
            .allocator = allocator,
        };
    } 

    pub fn readData(self: *PPMImage) PPMErr!void {
        self.file.seekTo(0) catch return PPMErr.NotAPPM;
        var magic_nr = std.mem.zeroes([2]u8);
        var one_byte = std.mem.zeroes([1]u8);
        if ((self.file.read(&magic_nr) catch return PPMErr.NotAPPM) != 2) return PPMErr.NotAPPM;
        if (magic_nr[0] != 0x50 and magic_nr[1] != 0x36) return PPMErr.NotAPPM;
        if ((self.file.read(&one_byte) catch return PPMErr.NotAPPM) != 1) return PPMErr.NotAPPM;
        if (one_byte[0] != 0x0A) return PPMErr.NotAPPM;
        
        var width: i32 = 0;
        if ((self.file.read(&one_byte) catch return PPMErr.NotAPPM) != 1) return PPMErr.NotAPPM;
        while (one_byte[0] != 0x20) {
            if (!std.ascii.isDigit(one_byte[0])) return PPMErr.NotAPPM;
            const digit: i32 = one_byte[0] - '0';
            width *= 10;
            width += digit;
            if ((self.file.read(&one_byte) catch return PPMErr.NotAPPM) != 1) return PPMErr.NotAPPM;
        }

        var height: i32 = 0;
        if ((self.file.read(&one_byte) catch return PPMErr.NotAPPM) != 1) return PPMErr.NotAPPM;
        while (one_byte[0] != 0x0A) {
            if (!std.ascii.isDigit(one_byte[0])) return PPMErr.NotAPPM;
            const digit: i32 = one_byte[0] - '0';
            height *= 10;
            height += digit;
            if ((self.file.read(&one_byte) catch return PPMErr.NotAPPM) != 1) return PPMErr.NotAPPM;
        }

        var max_cv: i32 = 0;
        if ((self.file.read(&one_byte) catch return PPMErr.NotAPPM) != 1) return PPMErr.NotAPPM;
        while (one_byte[0] != 0x0A) {
            if (!std.ascii.isDigit(one_byte[0])) return PPMErr.NotAPPM;
            const digit: i32 = one_byte[0] - '0';
            max_cv *= 10;
            max_cv += digit;
            if ((self.file.read(&one_byte) catch return PPMErr.NotAPPM) != 1) return PPMErr.NotAPPM;
        }

        self.width = width;
        self.height = height;

        const img_buff = self.allocator.alloc([]RGBAColor, @as(usize, @intCast(width))) catch return PPMErr.memErr;
        for (img_buff) |*row| {
            row.* = self.allocator.alloc(RGBAColor, @as(usize, @intCast(height))) catch return PPMErr.memErr;
        }

        self.buffer = img_buff;
        
        for (0..@as(usize, @intCast(height))) |y| {
            for (0..@as(usize, @intCast(width))) |x| {
                var pixel_color = RGBAColor{.r = 0, .g = 0, .b = 0, .a = 255,};
                if ((self.file.read(&one_byte) catch return PPMErr.NotAPPM) != 1) return PPMErr.NotAPPM;
                pixel_color.r = one_byte[0];
                if ((self.file.read(&one_byte) catch return PPMErr.NotAPPM) != 1) return PPMErr.NotAPPM;
                pixel_color.g = one_byte[0];
                if ((self.file.read(&one_byte) catch return PPMErr.NotAPPM) != 1) return PPMErr.NotAPPM;
                pixel_color.b = one_byte[0];

                self.buffer[x][y] = pixel_color;
            }
        }
    }

    pub fn deinit(self: *PPMImage) void {
        for (self.buffer) |row| {
            self.allocator.free(row);
        }
        self.allocator.free(self.buffer);
    }

    pub const PPMErr = error {
        NotAPPM,
        memErr
    };
};