# ============================================================================
# Visual Regression Testing for Template Layout
# ============================================================================
#
# Tests header, footer, page layout, and other visual aspects by:
# 1. Compiling .typ files to PNG images
# 2. Computing image hashes for comparison
# 3. Storing hashes as snapshots
# 4. Generating diff images on failure
#
# Usage:
#   test_visual("test_name", typst_code; update=false)
#
# Update snapshots:
#   UPDATE_SNAPSHOTS=1 julia test/runtests.jl

using SHA
using Typst_jll: typst as typst_exe

"""
    test_visual(name::String, typst_code::String; update::Bool=false, pages::Union{Vector{Int}, Nothing}=nothing)

Visual regression test for template layout features.

Compiles Typst code to PNG, computes hash, and compares against saved snapshot.

# Arguments
- `name`: Test name (used for snapshot filename)
- `typst_code`: Complete Typst document code
- `update`: If true, update snapshot hash
- `pages`: Which pages to test (default: `nothing` = auto-detect all pages)

# Example
```julia
# Auto-detect all pages
test_visual("header_chapter", \"\"\"
#import "documenter.typ": *
#show: documenter.with(title: "Test")
= Chapter 1
Content
\"\"\")

# Or specify specific pages
test_visual("header_chapter", \"\"\"...\"\"\"; pages=[1, 2])
```
"""
function test_visual(name::String, typst_code::String; update::Bool = false, pages::Union{Vector{Int}, Nothing} = nothing)
    snapshot_dir = joinpath(@__DIR__, "snapshots", "visual")
    mkpath(snapshot_dir)

    return mktempdir() do tmpdir
        # Copy documenter.typ template
        template_src = joinpath(dirname(@__DIR__), "assets", "documenter.typ")
        cp(template_src, joinpath(tmpdir, "documenter.typ"))

        # Write test file
        test_file = joinpath(tmpdir, "test.typ")
        write(test_file, typst_code)

        # Compile to PNG
        png_dir = joinpath(tmpdir, "output")
        mkpath(png_dir)

        try
            # Compile with Typst (generates test-{page}.png for each page)
            run(
                pipeline(
                    `$(typst_exe()) compile $test_file --format png "$png_dir/test-{p}.png"`,
                    stderr = devnull,
                    stdout = devnull
                )
            )
        catch e
            @error "Failed to compile" test_name = name exception = e
            @test false  # Mark test as failed
            return
        end

        # Auto-detect pages if not specified
        if isnothing(pages)
            png_files = filter(f -> occursin(r"^test-\d+\.png$", f), readdir(png_dir))
            pages = sort([parse(Int, match(r"test-(\d+)\.png", f)[1]) for f in png_files])

            if isempty(pages)
                @error "No PNG files generated" test_name = name png_dir = png_dir
                @test false
                return
            end
        end

        # Compute hashes for requested pages
        page_hashes = Dict{Int, String}()
        for page in pages
            png_file = joinpath(png_dir, "test-$page.png")

            if !isfile(png_file)
                @error "PNG file not generated" page = page test_name = name
                @test false  # Mark test as failed
                continue
            end

            # Compute SHA256 hash of PNG
            hash = bytes2hex(sha256(read(png_file)))
            page_hashes[page] = hash

            # Save PNG for manual inspection on failure
            failure_dir = joinpath(snapshot_dir, "failures")
            if !update
                snapshot_file = joinpath(snapshot_dir, "$(name)_page$(page).hash")
                if isfile(snapshot_file)
                    expected_hash = strip(read(snapshot_file, String))
                    if hash != expected_hash
                        # Save failed PNG for inspection
                        mkpath(failure_dir)
                        cp(png_file, joinpath(failure_dir, "$(name)_page$(page)_actual.png"), force = true)

                        println("\n" * "="^80)
                        println("❌ VISUAL REGRESSION: $name (page $page)")
                        println("="^80)
                        println("  Expected hash: $expected_hash")
                        println("  Actual hash:   $hash")
                        println("\n📂 Actual PNG saved to:")
                        println("   test/snapshots/visual/failures/$(name)_page$(page)_actual.png")
                        println("\n📝 To update this snapshot:")
                        println("   UPDATE_SNAPSHOTS=1 julia --project=. test/runtests.jl")
                        println("="^80 * "\n")
                    end
                end
            end
        end

        # Update or verify snapshots
        if update
            for (page, hash) in page_hashes
                snapshot_file = joinpath(snapshot_dir, "$(name)_page$(page).hash")
                write(snapshot_file, hash)

                # Also save reference PNG for documentation
                png_file = if length(pages) == 1 && page == 1
                    joinpath(png_dir, "test.png")
                else
                    joinpath(png_dir, "test-$page.png")
                end
                reference_dir = joinpath(snapshot_dir, "references")
                mkpath(reference_dir)
                cp(png_file, joinpath(reference_dir, "$(name)_page$(page).png"), force = true)
            end
            @test_skip "Visual snapshot updated: $name"
        else
            for (page, hash) in page_hashes
                snapshot_file = joinpath(snapshot_dir, "$(name)_page$(page).hash")
                if !isfile(snapshot_file)
                    @error "No snapshot found" test_name = name page = page
                    @info "Run with UPDATE_SNAPSHOTS=1 to create snapshot"
                    @test false  # Mark test as failed
                else
                    expected_hash = strip(read(snapshot_file, String))
                    @test hash == expected_hash
                end
            end
        end
    end
end

"""
    clean_visual_failures()

Remove all failed PNG files from previous test runs.
"""
function clean_visual_failures()
    failure_dir = joinpath(@__DIR__, "snapshots", "visual", "failures")
    return if isdir(failure_dir)
        rm(failure_dir, recursive = true)
    end
end

"""
    test_visual_from_file(name::String, typ_file::String; update::Bool=false, pages::Union{Vector{Int}, Nothing}=nothing)

Visual regression test using an existing .typ file (e.g., from integration fixtures).

Similar to `test_visual()`, but reads from an existing file instead of inline code.
Useful for testing complete documentation builds.

# Arguments
- `name`: Test name (used for snapshot filename)
- `typ_file`: Path to existing .typ file
- `update`: If true, update snapshot hash
- `pages`: Which pages to test (default: `nothing` = auto-detect all pages)

# Example
```julia
# Auto-detect all pages
test_visual_from_file("my_fixture", "test/integration/fixtures/my_fixture/build/output.typ")

# Or specify specific pages
test_visual_from_file("my_fixture", "test/integration/fixtures/my_fixture/build/output.typ"; pages=[1,3])
```
"""
function test_visual_from_file(name::String, typ_file::String; update::Bool = false, pages::Union{Vector{Int}, Nothing} = nothing)
    if !isfile(typ_file)
        @error "Typst file not found" typ_file = typ_file
        @test false  # Mark test as failed
        return
    end

    snapshot_dir = joinpath(@__DIR__, "snapshots", "visual")
    mkpath(snapshot_dir)

    return mktempdir() do tmpdir
        # Compile to PNG
        png_dir = joinpath(tmpdir, "output")
        mkpath(png_dir)

        try
            # Compile with Typst (generates output-{page}.png for each page)
            run(
                pipeline(
                    `$(typst_exe()) compile $typ_file --format png "$png_dir/output-{p}.png"`,
                    stderr = devnull,
                    stdout = devnull
                )
            )
        catch e
            @error "Failed to compile" test_name = name exception = e
            @test false  # Mark test as failed
            return
        end

        # Auto-detect pages if not specified
        if isnothing(pages)
            png_files = filter(f -> occursin(r"^output-\d+\.png$", f), readdir(png_dir))
            pages = sort([parse(Int, match(r"output-(\d+)\.png", f)[1]) for f in png_files])

            if isempty(pages)
                @error "No PNG files generated" test_name = name png_dir = png_dir
                @test false
                return
            end
        end

        # Compute hashes for requested pages
        page_hashes = Dict{Int, String}()
        for page in pages
            png_file = joinpath(png_dir, "output-$page.png")

            if !isfile(png_file)
                @error "PNG file not generated" page = page test_name = name
                @test false  # Mark test as failed
                continue
            end

            # Compute SHA256 hash of PNG
            hash = bytes2hex(sha256(read(png_file)))
            page_hashes[page] = hash

            # Save PNG for manual inspection on failure
            failure_dir = joinpath(snapshot_dir, "failures")
            if !update
                snapshot_file = joinpath(snapshot_dir, "$(name)_page$(page).hash")
                if isfile(snapshot_file)
                    expected_hash = strip(read(snapshot_file, String))
                    if hash != expected_hash
                        # Save failed PNG for inspection
                        mkpath(failure_dir)
                        cp(png_file, joinpath(failure_dir, "$(name)_page$(page)_actual.png"), force = true)

                        println("\n" * "="^80)
                        println("❌ VISUAL REGRESSION: $name (page $page)")
                        println("="^80)
                        println("  Expected hash: $expected_hash")
                        println("  Actual hash:   $hash")
                        println("\n📂 Actual PNG saved to:")
                        println("   test/snapshots/visual/failures/$(name)_page$(page)_actual.png")
                        println("\n📝 To update this snapshot:")
                        println("   UPDATE_SNAPSHOTS=1 julia --project=. test/runtests.jl")
                        println("="^80 * "\n")
                    end
                end
            end
        end

        # Update or verify snapshots
        if update
            for (page, hash) in page_hashes
                snapshot_file = joinpath(snapshot_dir, "$(name)_page$(page).hash")
                write(snapshot_file, hash)

                # Also save reference PNG for documentation
                png_file = if length(pages) == 1 && page == 1
                    joinpath(png_dir, "output.png")
                else
                    joinpath(png_dir, "output-$page.png")
                end
                reference_dir = joinpath(snapshot_dir, "references")
                mkpath(reference_dir)
                cp(png_file, joinpath(reference_dir, "$(name)_page$(page).png"), force = true)
            end
            @test_skip "Visual snapshot updated: $name"
        else
            for (page, hash) in page_hashes
                snapshot_file = joinpath(snapshot_dir, "$(name)_page$(page).hash")
                if !isfile(snapshot_file)
                    @error "No snapshot found" test_name = name page = page
                    @info "Run with UPDATE_SNAPSHOTS=1 to create snapshot"
                    @test false  # Mark test as failed
                else
                    expected_hash = strip(read(snapshot_file, String))
                    @test hash == expected_hash
                end
            end
        end
    end
end
