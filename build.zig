const std = @import("std");
const Build = std.Build;

pub fn build(b: *Build) !void {
    const prefered_target = std.zig.CrossTarget{
        .abi = .msvc,
        .cpu_arch = .x86_64,
        .os_tag = .windows,
    };

    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{ .default_target = prefered_target });

    // Build the tvision library
    const tvision = try addTVisionLibraryStep(b, .{ .optimize = optimize, .target = target });

    var tvision_step = b.step("tvision", "build tvision library");
    tvision_step.dependOn(&tvision.step);

    b.installArtifact(tvision);

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
    examples_step.dependOn(&hello.step);
    examples_step.dependOn(&mmenu.step);
    examples_step.dependOn(&tvedit.step);
    examples_step.dependOn(&tvdemo.step);
    examples_step.dependOn(&tvforms.step);
    examples_step.dependOn(&tvhc.step);
    examples_step.dependOn(&palette.step);
    examples_step.dependOn(&tvdir.step);

    examples_step.owner.installArtifact(hello);
    examples_step.owner.installArtifact(mmenu);
    examples_step.owner.installArtifact(palette);
    examples_step.owner.installArtifact(tvdir);
    examples_step.owner.installArtifact(tvedit);
    examples_step.owner.installArtifact(tvdemo);
    examples_step.owner.installArtifact(tvforms);
    examples_step.owner.installArtifact(tvhc);

    examples_step.dependOn(b.getInstallStep());
}

fn addTVisionLibraryStep(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
}) !*Build.Step.Compile {

    // build tvision library
    const tvision = b.addStaticLibrary(.{
        .name = "tvision",
        .optimize = options.optimize,
        .target = options.target,
    });

    tvision.addIncludePath(b.path("include"));
    tvision.addIncludePath(b.path("include/tvision"));
    tvision.addIncludePath(b.path("include/tvision/compat/borland"));
    tvision.linkLibC();

    var sources = std.ArrayList([]const u8).init(b.allocator);

    const source_dir = try std.fs.cwd().openDir("source", .{ .iterate = true });
    var sd_iter = try source_dir.walk(b.allocator);
    defer sd_iter.deinit();

    while (try sd_iter.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.basename, ".cpp") and !std.mem.eql(u8, entry.basename, "geninc.cpp")) {
            const str = b.fmt("source/{s}", .{entry.path});
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
    target: std.Build.ResolvedTarget,
}) !*Build.Step.Compile {
    var hello = b.addExecutable(.{
        .name = "hello",
        .optimize = options.optimize,
        .target = options.target,
    });
    hello.addCSourceFile(.{
        .file = b.path("hello.cpp"),
        .flags = &.{
            "-std=c++14",
        },
    });
    hello.addIncludePath(b.path("include"));
    hello.linkLibC();
    if (options.target.result.os.tag == .windows) {
        hello.linkSystemLibrary("user32");
    }

    return hello;
}

fn addExampleMMenu(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
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
    mmenu.addIncludePath(b.path("include"));
    mmenu.addIncludePath(b.path("include/tvision"));
    mmenu.linkLibC();
    if (options.target.result.os.tag == .windows) {
        mmenu.linkSystemLibrary("user32");
    }
    return mmenu;
}
fn addExampleTVedit(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
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
    tvedit.addIncludePath(b.path("include"));
    tvedit.addIncludePath(b.path("include/tvision/compat/borland"));

    if (options.target.result.os.tag == .windows) {
        tvedit.linkSystemLibrary("user32");
    }
    return tvedit;
}

fn addExamplePalette(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
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
    palette.addIncludePath(b.path("include"));
    palette.addIncludePath(b.path("include/tvision"));
    palette.addIncludePath(b.path("include/tvision/compat/borland"));
    palette.linkLibC();

    if (options.target.result.os.tag == .windows) {
        palette.linkSystemLibrary("user32");
    }
    return palette;
}

fn addExampleTVdemo(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
}) !*Build.Step.Compile {
    var tvdemo = b.addExecutable(.{
        .name = "tvdemo",
        .optimize = options.optimize,
        .target = options.target,
    });

    tvdemo.addIncludePath(b.path("include"));
    tvdemo.addIncludePath(b.path("include/tvision"));
    tvdemo.addIncludePath(b.path("include/tvision/compat/borland"));
    tvdemo.linkLibC();

    var sources = std.ArrayList([]const u8).init(b.allocator);

    const source_dir = try std.fs.cwd().openDir("examples/tvdemo", .{ .iterate = true });
    var sd_iter = try source_dir.walk(b.allocator);
    defer sd_iter.deinit();

    while (try sd_iter.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.basename, ".cpp")) {
            const str = b.fmt("examples/tvdemo/{s}", .{entry.path});
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

    if (options.target.result.os.tag == .windows) {
        tvdemo.linkSystemLibrary("user32");
    }
    return tvdemo;
}

fn addExampleTVdir(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
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
    tvdir.addIncludePath(b.path("include"));
    tvdir.addIncludePath(b.path("include/tvision"));
    tvdir.addIncludePath(b.path("include/tvision/compat/borland"));
    tvdir.linkLibC();

    if (options.target.result.os.tag == .windows) {
        tvdir.linkSystemLibrary("user32");
    }
    return tvdir;
}

fn addExampleTVforms(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
}) !*Build.Step.Compile {
    var tvforms = b.addExecutable(.{
        .name = "tvforms",
        .optimize = options.optimize,
        .target = options.target,
    });

    var sources = std.ArrayList([]const u8).init(b.allocator);

    const source_dir = try std.fs.cwd().openDir("examples/tvforms", .{ .iterate = true });
    var sd_iter = try source_dir.walk(b.allocator);
    defer sd_iter.deinit();

    while (try sd_iter.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.basename, ".cpp") and !std.mem.eql(u8, entry.basename, "genform.cpp")) {
            const str = b.fmt("examples/tvforms/{s}", .{entry.path});
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

    tvforms.addIncludePath(b.path("include"));
    tvforms.addIncludePath(b.path("include/tvision"));
    tvforms.addIncludePath(b.path("include/tvision/compat/borland"));
    tvforms.linkLibC();

    if (options.target.result.os.tag == .windows) {
        tvforms.linkSystemLibrary("user32");
    }
    return tvforms;
}

fn addExampleTVhc(b: *Build, options: struct {
    optimize: std.builtin.OptimizeMode,
    target: std.Build.ResolvedTarget,
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

    tvhc.addIncludePath(b.path("include"));
    tvhc.addIncludePath(b.path("include/tvision"));
    tvhc.addIncludePath(b.path("include/tvision/compat/borland"));
    tvhc.linkLibC();

    if (options.target.result.os.tag == .windows) {
        tvhc.linkSystemLibrary("user32");
    }
    return tvhc;
}
