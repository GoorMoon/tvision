const std = @import("std");
const Build = std.build;

pub fn build(b: *Build) !void {
    const preferedTarget = try std.zig.CrossTarget.parse(.{
        .arch_os_abi = "x86_64-windows-msvc",
    });
    var optimize = b.standardOptimizeOption(.{});
    var target = b.standardTargetOptions(.{ .default_target = preferedTarget });

    // Build the tvision library
    var tvision = try addTVisionLibraryStep(b, .{ .optimize = optimize, .target = target });
    var tvision_step = b.step("tvision", "build tvision library");
    var tvision_art = std.Build.Step.InstallArtifact.create(tvision_step.owner, tvision);
    tvision_step.dependOn(&tvision_art.step);

    // Build Hello Library
    var hello = try addExampleHello(b, .{ .optimize = optimize, .target = target });
    hello.step.dependOn(&tvision.step);
    hello.linkLibrary(tvision);

    var hello_step = b.step("hello", "build hello demo");
    var hello_art = std.Build.Step.InstallArtifact.create(hello_step.owner, hello);
    hello_step.dependOn(&hello_art.step);

    // build examples
    // mmenu
    var mmenu = try addExampleMMenu(b, .{ .optimize = optimize, .target = target });
    mmenu.linkLibrary(tvision);
    // tvedit
    var tvedit = try addExampleTVedit(b, .{ .optimize = optimize, .target = target });
    tvedit.linkLibrary(tvision);

    var examples_step = b.step("examples", "build tvision examples");
    var mmenu_art = std.Build.Step.InstallArtifact.create(examples_step.owner, mmenu);
    var tvedit_art = std.Build.Step.InstallArtifact.create(examples_step.owner, tvedit);
    _ = tvedit_art;
    examples_step.dependOn(&mmenu_art.step);
    // examples_step.dependOn(&tvedit_art.step);

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

    tvision.addIncludePath("include");
    tvision.addIncludePath("include/tvision");
    tvision.addIncludePath("include/tvision/compat/borland");
    tvision.linkLibC();

    var sources = std.ArrayList([]const u8).init(b.allocator);
    // defer sources.deinit();

    const source_dir = try std.fs.cwd().openIterableDir("source", .{});
    var sd_iter = try source_dir.walk(b.allocator);
    defer sd_iter.deinit();

    while (try sd_iter.next()) |entry| {
        if (entry.kind == .File and std.mem.endsWith(u8, entry.basename, ".cpp") and !std.mem.eql(u8, entry.basename, "geninc.cpp")) {
            var str = b.fmt("source\\{s}", .{entry.path});
            try sources.append(str);
        }
    }

    tvision.addCSourceFiles(sources.items, &.{
        "-std=c++14",
        "-Wno-c++11-narrowing",
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
    hello.addCSourceFile("hello.cpp", &.{
        "-std=c++14",
    });
    hello.addIncludePath("include");
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
    mmenu.addCSourceFiles(&.{
        "examples\\mmenu\\test.cpp",
        "examples\\mmenu\\mmenu.cpp",
    }, &.{
        "-std=c++14",
    });
    mmenu.addIncludePath("include");
    mmenu.addIncludePath("include\\tvision");
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
    tvedit.addCSourceFiles(&.{
        "examples\\tvedit\\tvedit1.cpp",
        "examples\\tvedit\\tvedit2.cpp",
        "examples\\tvedit\\tvedit3.cpp",
    }, &.{
        "-std=c++14",
        "-Wno-c++11-narrowing",
    });
    tvedit.addIncludePath("include");
    tvedit.addIncludePath("include\\tvision\\compat\\borland");
    tvedit.linkLibC();

    if (options.target.os_tag.? == .windows) {
        tvedit.linkSystemLibrary("user32");
    }
    return tvedit;
}
