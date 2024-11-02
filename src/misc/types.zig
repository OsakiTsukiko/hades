const rl = @import("raylib");

pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn new(x: f32, y: f32) Vec2 {
        return Vec2{.x = x, .y = y};
    }

    pub fn toVec2i(self: *const Vec2) Vec2i {
        return Vec2i{
            .x = @as(i32, @intFromFloat(self.x)),
            .y = @as(i32, @intFromFloat(self.y)),
        };
    }

    pub fn toRaylib(self: *const Vec2) rl.Vector2 {
        return rl.Vector2{
            .x = self.x,
            .y = self.y,
        };
    }

    pub fn fromRaylib(vec: rl.Vector2) Vec2 {
        return Vec2{
            .x = vec.x,
            .y = vec.y,
        };
    }

    pub fn add(self: *Vec2, nr: f32) void {
        self.x += nr;
        self.y += nr;
    }
    
    pub fn addn(self: *const Vec2, nr: f32) Vec2 {
        return Vec2{
            .x = self.x + nr,
            .y = self.y + nr,
        };
    }

    pub fn sub(self: *Vec2, nr: f32) void {
        self.x -= nr;
        self.y -= nr;
    }

    pub fn subn(self: *const Vec2, nr: f32) Vec2 {
        return Vec2{
            .x = self.x - nr,
            .y = self.y - nr,
        };
    }

    pub fn mul(self: *Vec2, nr: f32) void {
        self.x *= nr;
        self.y *= nr;
    }

    pub fn muln(self: *const Vec2, nr: f32) Vec2 {
        return Vec2{
            .x = self.x * nr,
            .y = self.y * nr,
        };
    }

    pub fn div(self: *Vec2, nr: f32) void {
        self.x /= nr;
        self.y /= nr;
    }
    
    pub fn divn(self: *const Vec2, nr: f32) Vec2 {
        return Vec2{
            .x = self.x / nr,
            .y = self.y / nr,
        };
    }
};

pub const Vec2i = struct {
    x: i32,
    y: i32,

    pub fn new(x: i32, y: i32) Vec2i {
        return Vec2i{.x = x, .y = y};
    }

    pub fn fromUsize(x: usize, y: usize) Vec2i {
        return Vec2i{
            .x = @as(i32, @intCast(x)),
            .y = @as(i32, @intCast(y)),
        };
    }

    pub fn toVec2(self: *const Vec2i) Vec2 {
        return Vec2{
            .x = @as(f32, @floatFromInt(self.x)),
            .y = @as(f32, @floatFromInt(self.y)),
        };
    }

    pub fn add(self: *Vec2i, nr: i32) void {
        self.x += nr;
        self.y += nr;
    }

    pub fn addv(self: *Vec2i, other: Vec2i) void {
        self.x += other.x;
        self.y += other.y;
    }
    
    pub fn addn(self: *const Vec2i, nr: i32) Vec2i {
        return Vec2i{
            .x = self.x + nr,
            .y = self.y + nr,
        };
    }

    pub fn addvn(self: *const Vec2i, other: Vec2i) Vec2i {
        return Vec2i{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    pub fn sub(self: *Vec2i, nr: i32) void {
        self.x -= nr;
        self.y -= nr;
    }

    pub fn subv(self: *Vec2i, other: Vec2i) void {
        self.x -= other.x;
        self.y -= other.y;
    }

    pub fn subn(self: *const Vec2i, nr: i32) Vec2i {
        return Vec2i{
            .x = self.x - nr,
            .y = self.y - nr,
        };
    }

    pub fn subvn(self: *const Vec2i, other: Vec2i) Vec2i {
        return Vec2i{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }

    pub fn mul(self: *Vec2i, nr: i32) void {
        self.x *= nr;
        self.y *= nr;
    }

    pub fn muln(self: *const Vec2i, nr: i32) Vec2i {
        return Vec2i{
            .x = self.x * nr,
            .y = self.y * nr,
        };
    }

    pub fn div(self: *Vec2i, nr: i32) void {
        self.x = @divFloor(self.x, nr);
        self.y = @divFloor(self.y, nr);
    }
    
    pub fn divn(self: *const Vec2i, nr: i32) Vec2i {
        return Vec2i{
            .x = @divFloor(self.x, nr),
            .y = @divFloor(self.y, nr),
        };
    }
};