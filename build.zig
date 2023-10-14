const std = @import("std");
const Build = std.build;

pub fn build(b: *Build) !void {
    const prefered_target = std.zig.CrossTarget{
        .abi = .msvc,
        .cpu_arch = .x86_64,
        .os_tag = .windows,
    };

    var optimize = b.standardOptimizeOption(.{});
    var target = b.standardTargetOptions(.{ .default_target = prefered_target });

    // Build the tvision library
    var tvision = try addTVisionLibraryStep(b, .{ .optimize = optimize, .target = target });
    var tvision_step = b.step("tvision", "build tvision library");
    var tvision_art = std.Build.Step.InstallArtifact.create(tvision_step.owner, tvision, .{});
    tvision_step.dependOn(&tvision_art.step);

    //* -------------- */
    //* build examples */
    //* -------------- */

    // hello
    var hello = try addExampleHello(b, .{ .optimize = optimize, .target = target });
    hello.linkLibrary(tvision);

    // mmenu
    var mmenu = try addExampleMMenu(b, .{ .optimize = optimize, .target = target });
    mmenu.linkLibrary(tvision);

    // tvedit
    var tvedit = try addExampleTVedit(b, .{ .optimize = optimize, .target = target });
    tvedit.linkLibrary(tvision);

    // palette
    var palette = try addExamplePalette(b, .{ .optimize = optimize, .target = target });
    palette.linkLibrary(tvision);

    // tvdemo
    var tvdemo = try addExampleTVdemo(b, .{ .optimize = optimize, .target = target });
    tvdemo.linkLibrary(tvision);

    // tvdir
    var tvdir = try addExampleTVdir(b, .{ .optimize = optimize, .target = target });
    tvdir.linkLibrary(tvision);

    // tvforms
    var tvforms = try addExampleTVforms(b, .{ .optimize = optimize, .target = target });
    tvforms.linkLibrary(tvision);

    // tvhc
    var tvhc = try addExampleTVhc(b, .{ .optimize = optimize, .target = target });
    tvhc.linkLibrary(tvision);

    var examples_step = b.step("examples", "build tvision examples");
    var hello_art = std.Build.Step.InstallArtifact.create(examples_step.owner, hello, .{});
    var mmenu_art = std.Build.Step.InstallArtifact.create(examples_step.owner, mmenu, .{});
    var tvedit_art = std.Build.Step.InstallArtifact.create(examples_step.owner, tvedit, .{});
    var palette_art = std.Build.Step.InstallArtifact.create(examples_step.owner, palette, .{});
    var tvdemo_art = std.Build.Step.InstallArtifact.create(examples_step.owner, tvdemo, .{});
    var tvdir_art = std.Build.Step.InstallArtifact.create(examples_step.owner, tvdir, .{});
    var tvforms_art = std.Build.Step.InstallArtifact.create(examples_step.owner, tvforms, .{});
    var tvhc_art = std.Build.Step.InstallArtifact.create(examples_step.owner, tvhc, .{});

    _ = tvforms_art;
    _ = tvdemo_art;
    _ = tvedit_art;
    _ = tvhc_art;

    examples_step.dependOn(&hello_art.step);
    examples_step.dependOn(&mmenu_art.step);
    // examples_step.dependOn(&tvedit_art.step);
    // examples_step.dependOn(&tvdemo_art.step);
    // examples_step.dependOn(&tvforms_art.step);
    // examples_step.dependOn(&tvhc_art.step);
    examples_step.dependOn(&palette_art.step);
    examples_step.dependOn(&tvdir_art.step);

    b.default_step.dependOn(tvision_step);
}

fn addTVisionLibraryStep(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.zig.CrossTarget,
}) !*Build.Step.Compile {

    // build tvision library
    const tvision = b.addStaticLibrary(.{
        .name = "tvision",
        .optimize = options.optimize,
        .target = options.target,
    });

    tvision.addIncludePath(.{ .path = "include" });
    tvision.addIncludePath(.{ .path = "include/tvision" });
    tvision.addIncludePath(.{ .path = "include/tvision/compat/borland" });
    tvision.linkLibC();

    var sources = std.ArrayList([]const u8).init(b.allocator);

    const source_dir = try std.fs.cwd().openIterableDir("source", .{});
    var sd_iter = try source_dir.walk(b.allocator);
    defer sd_iter.deinit();

    while (try sd_iter.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.basename, ".cpp") and !std.mem.eql(u8, entry.basename, "geninc.cpp")) {
            var str = b.fmt("source/{s}", .{entry.path});
            try sources.append(str);
        }
    }

    tvision.addCSourceFiles(.{
        .files = sources.items,
        .flags = &.{
            "-std=c++14",
            "-Wno-c++11-narrowing",
        },
    });

    return tvision;
}

fn addExampleHello(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.zig.CrossTarget,
}) !*Build.Step.Compile {
    var hello = b.addExecutable(.{
        .name = "hello",
        .optimize = options.optimize,
        .target = options.target,
    });
    hello.addCSourceFile(.{
        .file = .{ .path = "hello.cpp" },
        .flags = &.{
            "-std=c++14",
        },
    });
    hello.addIncludePath(.{ .path = "include" });
    hello.linkLibC();
    if (options.target.os_tag.? == .windows) {
        hello.linkSystemLibrary("user32");
    }

    return hello;
}

fn addExampleMMenu(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.zig.CrossTarget,
}) !*Build.Step.Compile {
    var mmenu = b.addExecutable(.{
        .name = "mmenu",
        .optimize = options.optimize,
        .target = options.target,
    });
    mmenu.addCSourceFiles(.{
        .files = &.{
            "examples/mmenu/test.cpp",
            "examples/mmenu/mmenu.cpp",
        },
        .flags = &.{
            "-std=c++14",
        },
    });
    mmenu.addIncludePath(.{ .path = "include" });
    mmenu.addIncludePath(.{ .path = "include/tvision" });
    mmenu.linkLibC();
    if (options.target.os_tag.? == .windows) {
        mmenu.linkSystemLibrary("user32");
    }
    return mmenu;
}
fn addExampleTVedit(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.zig.CrossTarget,
}) !*Build.Step.Compile {
    var tvedit = b.addExecutable(.{
        .name = "tvedit",
        .optimize = options.optimize,
        .target = options.target,
    });
    tvedit.addCSourceFiles(.{
        .files = &.{
            "examples/tvedit/tvedit1.cpp",
            "examples/tvedit/tvedit2.cpp",
            "examples/tvedit/tvedit3.cpp",
        },
        .flags = &.{
            "-std=c++14",
            "-Wno-c++11-narrowing",
        },
    });
    tvedit.addIncludePath(.{ .path = "include" });
    tvedit.addIncludePath(.{ .path = "include/tvision/compat/borland" });
    tvedit.linkLibC();

    if (options.target.os_tag.? == .windows) {
        tvedit.linkSystemLibrary("user32");
    }
    return tvedit;
}

fn addExamplePalette(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.zig.CrossTarget,
}) !*Build.Step.Compile {
    var palette = b.addExecutable(.{
        .name = "palette",
        .optimize = options.optimize,
        .target = options.target,
    });
    palette.addCSourceFiles(.{
        .files = &.{
            "examples/palette/test.cpp",
            "examples/palette/palette.cpp",
        },
        .flags = &.{
            "-std=c++14",
            "-Wno-c++11-narrowing",
        },
    });
    palette.addIncludePath(.{ .path = "include" });
    palette.addIncludePath(.{ .path = "include/tvision" });
    palette.addIncludePath(.{ .path = "include/tvision/compat/borland" });
    palette.linkLibC();

    if (options.target.os_tag.? == .windows) {
        palette.linkSystemLibrary("user32");
    }
    return palette;
}

fn addExampleTVdemo(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.zig.CrossTarget,
}) !*Build.Step.Compile {
    var tvdemo = b.addExecutable(.{
        .name = "tvdemo",
        .optimize = options.optimize,
        .target = options.target,
    });

    tvdemo.addIncludePath(.{ .path = "include" });
    tvdemo.addIncludePath(.{ .path = "include/tvision" });
    tvdemo.addIncludePath(.{ .path = "include/tvision/compat/borland" });
    tvdemo.linkLibC();

    var sources = std.ArrayList([]const u8).init(b.allocator);

    const source_dir = try std.fs.cwd().openIterableDir("examples/tvdemo", .{});
    var sd_iter = try source_dir.walk(b.allocator);
    defer sd_iter.deinit();

    while (try sd_iter.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.basename, ".cpp")) {
            var str = b.fmt("examples/tvdemo/{s}", .{entry.path});
            try sources.append(str);
        }
    }

    tvdemo.addCSourceFiles(.{
        .files = sources.items,
        .flags = &.{
            "-std=c++14",
            "-Wno-c++11-narrowing",
        },
    });

    if (options.target.os_tag.? == .windows) {
        tvdemo.linkSystemLibrary("user32");
    }
    return tvdemo;
}

fn addExampleTVdir(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.zig.CrossTarget,
}) !*Build.Step.Compile {
    var tvdir = b.addExecutable(.{
        .name = "tvdir",
        .optimize = options.optimize,
        .target = options.target,
    });
    tvdir.addCSourceFiles(.{
        .files = &.{
            "examples/tvdir/tvdir.cpp",
        },
        .flags = &.{
            "-std=c++14",
            "-Wno-c++11-narrowing",
        },
    });
    tvdir.addIncludePath(.{ .path = "include" });
    tvdir.addIncludePath(.{ .path = "include/tvision" });
    tvdir.addIncludePath(.{ .path = "include/tvision/compat/borland" });
    tvdir.linkLibC();

    if (options.target.os_tag.? == .windows) {
        tvdir.linkSystemLibrary("user32");
    }
    return tvdir;
}

fn addExampleTVforms(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.zig.CrossTarget,
}) !*Build.Step.Compile {
    var tvforms = b.addExecutable(.{
        .name = "tvforms",
        .optimize = options.optimize,
        .target = options.target,
    });

    var sources = std.ArrayList([]const u8).init(b.allocator);

    const source_dir = try std.fs.cwd().openIterableDir("examples/tvforms", .{});
    var sd_iter = try source_dir.walk(b.allocator);
    defer sd_iter.deinit();

    while (try sd_iter.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.basename, ".cpp") and !std.mem.eql(u8, entry.basename, "genform.cpp")) {
            var str = b.fmt("examples/tvforms/{s}", .{entry.path});
            try sources.append(str);
        }
    }

    tvforms.addCSourceFiles(.{
        .files = sources.items,
        .flags = &.{
            "-std=c++14",
            "-Wno-c++11-narrowing",
        },
    });

    tvforms.addIncludePath(.{ .path = "include" });
    tvforms.addIncludePath(.{ .path = "include/tvision" });
    tvforms.addIncludePath(.{ .path = "include/tvision/compat/borland" });
    tvforms.linkLibC();

    if (options.target.os_tag.? == .windows) {
        tvforms.linkSystemLibrary("user32");
    }
    return tvforms;
}

fn addExampleTVhc(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.zig.CrossTarget,
}) !*Build.Step.Compile {
    var tvhc = b.addExecutable(.{
        .name = "tvhc",
        .optimize = options.optimize,
        .target = options.target,
    });

    tvhc.addCSourceFiles(.{
        .files = &.{
            "examples/tvhc/tvhc.cpp",
        },
        .flags = &.{
            "-std=c++14",
            "-Wno-c++11-narrowing",
        },
    });

    tvhc.addIncludePath(.{ .path = "include" });
    tvhc.addIncludePath(.{ .path = "include/tvision" });
    tvhc.addIncludePath(.{ .path = "include/tvision/compat/borland" });
    tvhc.linkLibC();

    if (options.target.os_tag.? == .windows) {
        tvhc.linkSystemLibrary("user32");
    }
    return tvhc;
}
