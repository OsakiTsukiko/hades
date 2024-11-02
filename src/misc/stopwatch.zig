const std = @import("std");

pub const MicroStopwatch = struct {
    time_start: i64,

    pub fn init() MicroStopwatch {
        return MicroStopwatch {
            .time_start = std.time.microTimestamp(),
        };
    }

    pub fn getTime(self: *const MicroStopwatch) i64 {
        return std.time.microTimestamp() - self.time_start;
    }
};

pub const NanoStopwatch = struct {
    time_start: i128,

    pub fn init() NanoStopwatch {
        return NanoStopwatch {
            .time_start = std.time.nanoTimestamp(),
        };
    }

    pub fn getTime(self: *const NanoStopwatch) i128 {
        return std.time.nanoTimestamp() - self.time_start;
    }
};
