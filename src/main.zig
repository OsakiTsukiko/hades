const std = @import("std");
const fs = std.fs;
const rl = @import("raylib");

// AUTOMATA
const BUFFER_TYPE = @import("./automata/world.zig").BUFFER_TYPE;
const Kernel = @import("./automata/kernel.zig").Kernel;
const World = @import("./automata/world.zig").World;
// MISC
const PPMImage = @import("./misc/ppm.zig").PPMImage;
const stopwatch = @import("./misc/stopwatch.zig");
const tp = @import("./misc/types.zig");
// UI
const Button = @import("./ui/button.zig").Button;

const buffer_print_width = 512;
const buffer_print_height = 512;
const scale = 2;
const buffer_width = buffer_print_width / scale;
const buffer_height = buffer_print_height / scale;

const win_width = 10 + buffer_print_width + 10 + 130 + 10;
const win_height = 10 + buffer_print_height + 10;

const thread_count = 16;
const thread_workload = buffer_height / (thread_count - 1);

const world_type = World(bool, buffer_width, buffer_height);

pub fn main() !void {
    // Initialize Allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true
    }){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // state
    var is_running: bool = false;
    var is_running_one_frame: bool = false;
    var use_multithreading: bool = true;
    var auto_swap: bool = true;

    // Initialize random
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    // Load Input
    const input_file = fs.cwd().openFile("input.ppm", .{}) catch unreachable;
    defer input_file.close();
    
    var input_ppm = PPMImage.init(allocator, input_file);
    defer input_ppm.deinit();
    input_ppm.readData() catch unreachable;

    // Load kernel files
    const inner_kernel_file = fs.cwd().openFile("smooth_inner_kernel.ppm", .{}) catch unreachable;
    defer inner_kernel_file.close();
    
    const outer_kernel_file = fs.cwd().openFile("smooth_outer_kernel.ppm", .{}) catch unreachable;
    defer outer_kernel_file.close();

    // Create PPM structs
    var inner_kernel_ppm = PPMImage.init(allocator, inner_kernel_file);
    defer inner_kernel_ppm.deinit();
    inner_kernel_ppm.readData() catch unreachable;
    
    var outer_kernel_ppm = PPMImage.init(allocator, outer_kernel_file);
    defer outer_kernel_ppm.deinit();
    outer_kernel_ppm.readData() catch unreachable;

    // Create Kernels
    var inner_kernel = Kernel.init(allocator);
    defer inner_kernel.deinit();
    inner_kernel.fromPPM(&inner_kernel_ppm);
    std.log.info("Inner Kernel Len: {d}", .{inner_kernel.mask_list.items.len});

    var outer_kernel = Kernel.init(allocator);
    defer outer_kernel.deinit();
    outer_kernel.fromPPM(&outer_kernel_ppm);
    std.log.info("Outer Kernel Len: {d}", .{outer_kernel.mask_list.items.len});

    // Initialize World
    var wld = world_type.init(false);

    // UI
    var play_pause_btn = Button.init(10 + buffer_print_width + 10, 10, 130, 20, "PLAY / PAUSE");
    play_pause_btn.on_click = play_pause_on_click;
    play_pause_btn.on_click_state = @as(*anyopaque, @ptrCast(&is_running));

    var one_frame_btn = Button.init(10 + buffer_print_width + 10, 10 + 30 * 1, 130, 20, "ONE FRAME");
    one_frame_btn.on_click = one_frame_on_click;
    one_frame_btn.on_click_state = @as(*anyopaque, @ptrCast(&is_running_one_frame));

    var swap_buffers_btn = Button.init(10 + buffer_print_width + 10, 10 + 30 * 2, 130, 20, "SWAP BUFFERS");
    swap_buffers_btn.on_click = swap_buffers_on_click;
    swap_buffers_btn.on_click_state = @as(*anyopaque, @ptrCast(&wld.current_buffer));
    
    var multithreading_btn = Button.init(10 + buffer_print_width + 10, 10 + 30 * 3, 130, 20, "TOGGLE THREADS");
    multithreading_btn.on_click = multithreading_on_click;
    multithreading_btn.on_click_state = @as(*anyopaque, @ptrCast(&use_multithreading));

    var auto_swap_btn = Button.init(10 + buffer_print_width + 10, 10 + 30 * 4, 130, 20, "TOGGLE AUTO SWAP");
    auto_swap_btn.on_click = autoswap_on_click;
    auto_swap_btn.on_click_state = @as(*anyopaque, @ptrCast(&auto_swap));

    // Initialize raylib
    rl.initWindow(win_width, win_height, "HADES - Complexity of Simplicity - Generalized Cellular Automaton");
    defer rl.closeWindow();

    // render texture for main buffer
    const target = rl.loadRenderTexture(buffer_print_width, buffer_print_height);
    const target_source = rl.Rectangle{ .x = 0.0, .y = 0.0, .width = buffer_print_width, .height = -buffer_print_height };
    const target_dest = rl.Rectangle{
        .x = 10.0, .y = 10.0,
        .width = buffer_print_height,
        .height = buffer_print_height,
    };

    var cam = std.mem.zeroes(rl.Camera2D);
    cam.zoom = scale;

    // TODO: In Game FPS adjustment (or PSEUDO FPS)
    // rl.setTargetFPS(60);

    // Load input into world
    for (0..@as(usize, @intCast(input_ppm.height))) |y| {
        for (0..@as(usize, @intCast(input_ppm.width))) |x| {
            if (input_ppm.buffer[x][y].r == 255) wld.setMain(x, y, true);
        }
    }

    while (!rl.windowShouldClose()) {
        // update UI
        play_pause_btn.update();
        one_frame_btn.update();
        swap_buffers_btn.update();
        multithreading_btn.update();
        auto_swap_btn.update();

        if (is_running) {
            world_rule(&wld, inner_kernel, outer_kernel, use_multithreading, auto_swap);
        } else if (is_running_one_frame) {
            is_running_one_frame = false;
            const sw = stopwatch.MicroStopwatch.init();
            world_rule(&wld, inner_kernel, outer_kernel, use_multithreading, auto_swap);
            std.debug.print("RULE: {d}\n", .{sw.getTime()});
        }
        
        world_draw(&wld, target, cam);
        { // drawing
            rl.beginDrawing();
            defer rl.endDrawing();

            rl.clearBackground(rl.Color.ray_white);
            rl.drawTexturePro(target.texture, target_source, target_dest, rl.Vector2.zero(), 0.0, rl.Color.white);
            rl.drawRectangleLinesEx(target_dest, 2.0, rl.Color{.r = 74, .g = 13, .b = 13, .a = 255});

            // draw UI
            play_pause_btn.draw();
            one_frame_btn.draw();
            swap_buffers_btn.draw();
            multithreading_btn.draw();
            auto_swap_btn.draw();

            rl.drawFPS(rl.getScreenWidth() - 90, rl.getScreenHeight() - 30);
        }

        if (rl.checkCollisionPointRec(rl.getMousePosition(), target_dest)) {
            if (rl.isMouseButtonDown(.mouse_button_left)) {
                const mouse_pos = rl.getMousePosition().subtractValue(10.0).divide(rl.Vector2.init(scale, scale));
                const pos = tp.Vec2.fromRaylib(mouse_pos).toVec2i();
                   
                var y = pos.y - 16;
                while (y <= pos.y + 16) {
                    var x = pos.x - 16;
                    while (x <= pos.x + 16) {
                        const p = tp.Vec2i.new(x, y);
                        wld.setMainV(p, rand.boolean());
                        x += 1; 
                    }
                    y += 1;
                }
            }
        }
    }
}

fn world_rule_chunk(wld: *world_type, inner_kernel: Kernel, outer_kernel: Kernel, start: usize, end: usize) void {
    for (start..end) |y| {
        for (0..buffer_width) |x| {
            const pos = tp.Vec2i.fromUsize(x, y);

            var inner_sum: f32 = 0.0;
            for (inner_kernel.mask_list.items) |k_pos| {
                if (wld.getMainV(pos.addvn(k_pos))) inner_sum += 1.0;
            }
            const inner_avrg = inner_sum / @as(f32, @floatFromInt(inner_kernel.mask_list.items.len));

            var outer_sum: f32 = 0.0;
            for (outer_kernel.mask_list.items) |k_pos| {
                if (wld.getMainV(pos.addvn(k_pos))) outer_sum += 1.0;
            }
            const outer_avrg = outer_sum / @as(f32, @floatFromInt(outer_kernel.mask_list.items.len));

            if (
                inner_avrg >= 0.5 and 0.26 <= outer_avrg and outer_avrg <= 0.46
            ) {
                wld.setBg(x, y, true);
            } else if (
                inner_avrg < 0.5 and 0.27 <= outer_avrg and outer_avrg <= 0.36
            ) {
                wld.setBg(x, y, true);
            } else {
                wld.setBg(x, y, false);
            }
        }
    }
}

fn world_rule(wld: *world_type, inner_kernel: Kernel, outer_kernel: Kernel, use_multithreading: bool, auto_swap: bool) void {
    if (use_multithreading) {
        var thread_array: [thread_count]std.Thread = undefined;

        for (0..thread_count) |thread_id| {
            if (thread_id != thread_count - 1) {
                const thread = std.Thread.spawn(.{}, world_rule_chunk, .{
                    wld,
                    inner_kernel, outer_kernel,
                    thread_id * thread_workload,
                    thread_id * thread_workload + thread_workload,
                }) catch unreachable;
                thread_array[thread_id] = thread;
            } else {
                // if (thread_id * thread_workload >= buffer_height) continue;
                const thread = std.Thread.spawn(.{}, world_rule_chunk, .{
                    wld,
                    inner_kernel, outer_kernel,
                    thread_id * thread_workload,
                    buffer_height,
                }) catch unreachable;
                thread_array[thread_id] = thread;
            }
        }

        for (thread_array, 0..) |thread, thread_id| {
            _ = thread_id;
            thread.join();
        }
    } else {
        for (0..buffer_height) |y| {
            for (0..buffer_width) |x| {
                const pos = tp.Vec2i.fromUsize(x, y);

                var inner_sum: f32 = 0.0;
                for (inner_kernel.mask_list.items) |k_pos| {
                    if (wld.getMainV(pos.addvn(k_pos))) inner_sum += 1.0;
                }
                const inner_avrg = inner_sum / @as(f32, @floatFromInt(inner_kernel.mask_list.items.len));

                var outer_sum: f32 = 0.0;
                for (outer_kernel.mask_list.items) |k_pos| {
                    if (wld.getMainV(pos.addvn(k_pos))) outer_sum += 1.0;
                }
                const outer_avrg = outer_sum / @as(f32, @floatFromInt(outer_kernel.mask_list.items.len));

                if (
                    inner_avrg >= 0.5 and 0.26 <= outer_avrg and outer_avrg <= 0.46
                ) {
                    wld.setBg(x, y, true);
                } else if (
                    inner_avrg < 0.5 and 0.27 <= outer_avrg and outer_avrg <= 0.36
                ) {
                    wld.setBg(x, y, true);
                } else {
                    wld.setBg(x, y, false);
                }
            }
        }
    }
    
    if (auto_swap) { wld.swapBuffers(); }
}

fn world_draw(wld: *const world_type, target: rl.RenderTexture2D, camera: rl.Camera2D) void {
    rl.beginTextureMode(target);
    defer rl.endTextureMode();

    rl.beginMode2D(camera);
    defer rl.endMode2D();

    if (wld.current_buffer == .MAIN_BUFFER) {
        rl.clearBackground(rl.Color.ray_white);

        for (0..buffer_height) |y| {
            for (0..buffer_width) |x| {
                const pos = tp.Vec2i.fromUsize(x, y);
                if (wld.getMain(x, y)) {
                    rl.drawPixel(pos.x, pos.y, rl.Color.red);
                }
            }
        }
    } else {
        rl.clearBackground(rl.Color.red);

        for (0..buffer_height) |y| {
            for (0..buffer_width) |x| {
                const pos = tp.Vec2i.fromUsize(x, y);
                if (wld.getBg(x, y)) {
                    rl.drawPixel(pos.x, pos.y, rl.Color.ray_white);
                }
            }
        }
    }
}

fn autoswap_on_click(optional_state: ?*anyopaque) void {
    if (optional_state) |state| {
        const auto_swap = @as(*bool, @ptrCast(state));
        auto_swap.* = !auto_swap.*;
    }
}

fn multithreading_on_click(optional_state: ?*anyopaque) void {
    if (optional_state) |state| {
        const use_multithreading = @as(*bool, @ptrCast(state));
        use_multithreading.* = !use_multithreading.*;
    }
}

fn play_pause_on_click(optional_state: ?*anyopaque) void {
    if (optional_state) |state| {
        const is_running = @as(*bool, @ptrCast(state));
        is_running.* = !is_running.*;
    }
}

fn one_frame_on_click(optional_state: ?*anyopaque) void {
    if (optional_state) |state| {
        const is_running_one_frame = @as(*bool, @ptrCast(state));
        is_running_one_frame.* = !is_running_one_frame.*;
    }
}

fn swap_buffers_on_click(optional_state: ?*anyopaque) void {
    if (optional_state) |state| {
        const current_buffer = @as(*BUFFER_TYPE, @ptrCast(state));
        switch (current_buffer.*) {
            .MAIN_BUFFER => {
                current_buffer.* = .BACKGROUND_BUFFER;
                return;
            },
            .BACKGROUND_BUFFER => {
                current_buffer.* = .MAIN_BUFFER;
                return;
            }
        }
    }
}
