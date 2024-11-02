const std = @import("std");
const rl = @import("raylib");
const tp = @import("../misc/types.zig");

pub const Button = struct {
    // config
    pos: tp.Vec2i,
    size: tp.Vec2i,
    rect: rl.Rectangle,
    text: [:0]const u8,
    font_size: i32 = 10,
    color: rl.Color = rl.Color.light_gray,
    accent_color: rl.Color = rl.Color.gray,
    hover_color: rl.Color = rl.Color.red,
    hover_accent_color: rl.Color = rl.Color{.r = 74, .g = 13, .b = 13, .a = 255},
    // state
    is_hovered: bool = false,

    on_click: ?*const fn (?*anyopaque) void = null,
    on_click_state: ?*anyopaque = null,

    pub fn init(x: f32, y: f32, width: f32, height: f32, text: [:0]const u8) Button {
        return Button {
            .pos = tp.Vec2.new(x, y).toVec2i(),
            .size = tp.Vec2.new(width, height).toVec2i(),
            .rect = rl.Rectangle{.x = x, .y = y, .width = width, .height = height},
            .text = text,
        };
    }

    pub fn update(self: *Button) void {
        if (rl.checkCollisionPointRec(rl.getMousePosition(), self.rect)) {
            self.is_hovered = true;
            if (rl.isMouseButtonReleased(.mouse_button_left)) if (self.on_click) |f| f(self.on_click_state);
        } else {
            self.is_hovered = false;
        }
    }

    pub fn draw(self: *const Button) void {
        rl.drawRectangleRec(self.rect, if (self.is_hovered) self.hover_color else self.color);
        rl.drawRectangleLines(
            self.pos.x, self.pos.y,
            self.size.x, self.size.y,
            if (self.is_hovered) self.hover_accent_color else self.accent_color,
        );
        rl.drawText(
            self.text, 
            self.pos.x + @divTrunc(self.size.x, 2) - @divTrunc(rl.measureText(self.text, self.font_size), 2),
            self.pos.y + @divTrunc(self.size.y, 2) - @divTrunc(self.font_size, 2),
            self.font_size, 
            if (self.is_hovered) self.hover_accent_color else self.accent_color,
        );
    }

};