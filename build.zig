const std = @import("std");
const Build = std.build;

pub fn build(b: *Build) !void {
    var optimize = b.standardOptimizeOption(.{});
    var target = b.standardTargetOptions(.{});

    // build tvision library
    const tvision = b.addStaticLibrary(.{
        .name = "tvision",
        .optimize = optimize,
        .target = target,
    });

    tvision.addIncludePath("include");
    tvision.addIncludePath("include/tvision");
    tvision.addIncludePath("include/tvision/compat/borland");
    tvision.linkLibC();

    var sources = std.ArrayList([]const u8).init(b.allocator);
    defer sources.deinit();

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

    var tvision_step = b.step("tvision", "build tvision library");
    var tvision_art = std.Build.Step.InstallArtifact.create(tvision_step.owner, tvision);
    tvision_step.dependOn(&tvision.step);
    tvision_step.dependOn(&tvision_art.step);

    var hello = b.addExecutable(.{
        .name = "hello",
        .optimize = optimize,
        .target = target,
    });
    hello.step.dependOn(&tvision.step);
    hello.addCSourceFile("hello.cpp", &.{
        "-std=c++14",
    });
    hello.addIncludePath("include");
    hello.linkLibC();
    hello.linkLibrary(tvision);
    hello.linkSystemLibrary("user32");

    // build hello.cpp
    var hello_step = b.step("hello", "build hello demo");
    var hello_art = std.Build.Step.InstallArtifact.create(hello_step.owner, hello);
    hello_step.dependOn(&hello.step);
    hello_step.dependOn(&hello_art.step);

    b.default_step.dependOn(tvision_step);
}
pub fn addTVisionLibraryStep(b: *Build) *Build.Step {
    _ = b;
}
