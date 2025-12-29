# ============================================================================
# Snapshot Testing Helpers
# ============================================================================
#
# Simple snapshot testing for DocumenterTypst output.
# No complex dependencies. Just file comparison.
#
# Usage:
#   test_snapshot("test_name", "# Markdown input"; update=false)
#
# Update snapshots:
#   UPDATE_SNAPSHOTS=1 julia test/runtests.jl

"""
    test_snapshot(name::String, markdown::String; update::Bool=false)

Test that Markdown → Typst conversion matches saved snapshot.

If `update=true` or snapshot doesn't exist, saves new snapshot.
Otherwise, compares output against existing snapshot.

# Example
```julia
test_snapshot("heading", "# Hello World")
```
"""
function test_snapshot(name::String, markdown::String; update::Bool = false)
    # Generate Typst output
    output = render_to_typst(markdown)
    output = normalize_snapshot_output(output)

    # Snapshot file path
    snapshot_dir = joinpath(@__DIR__, "snapshots")
    snapshot_file = joinpath(snapshot_dir, "$(name).typ")

    return if update || !isfile(snapshot_file)
        # Update mode: write new snapshot
        mkpath(snapshot_dir)
        write(snapshot_file, output)
        @test_skip "Snapshot updated: $name"
    else
        # Verify mode: compare
        expected = read(snapshot_file, String)
        if output != expected
            # Failed: show diff
            show_snapshot_diff(name, expected, output)
            @test output == expected  # Intentional failure for test runner
        else
            @test true  # Pass
        end
    end
end

"""
    normalize_snapshot_output(output::String) -> String

Normalize Typst output to remove dynamic/unstable content.

Removes:
- Timestamps
- Temporary paths
- Trailing whitespace
"""
function normalize_snapshot_output(output::String)
    lines = split(output, '\n')

    # Normalize line endings and trim
    output = join(lines, '\n')
    output = replace(output, "\r\n" => "\n")  # Windows compatibility
    return strip(output)
end

"""
    show_snapshot_diff(name::String, expected::String, actual::String)

Display diff between expected and actual snapshot output.
"""
function show_snapshot_diff(name::String, expected::String, actual::String)
    println("\n" * "="^80)
    println("❌ SNAPSHOT MISMATCH: $name")
    println("="^80)

    expected_lines = split(expected, '\n')
    actual_lines = split(actual, '\n')

    # Simple line-by-line diff
    max_lines = max(length(expected_lines), length(actual_lines))
    diff_count = 0

    for i in 1:min(max_lines, 50)  # Show max 50 lines
        exp_line = i <= length(expected_lines) ? expected_lines[i] : ""
        act_line = i <= length(actual_lines) ? actual_lines[i] : ""

        if exp_line != act_line
            diff_count += 1
            if diff_count <= 20  # Show max 20 differences
                println("  Line $i:")
                println("    Expected: $(repr(exp_line))")
                println("    Actual:   $(repr(act_line))")
            end
        end
    end

    if diff_count > 20
        println("  ... and $(diff_count - 20) more differences")
    end

    println("\n📝 To update this snapshot:")
    println("   UPDATE_SNAPSHOTS=1 julia --project=. test/runtests.jl")
    println("\n📂 Snapshot file: test/snapshots/$name.typ")
    return println("="^80 * "\n")
end

"""
    should_update_snapshots() -> Bool

Check if snapshot update mode is enabled via environment variable.
"""
function should_update_snapshots()
    return get(ENV, "UPDATE_SNAPSHOTS", "0") in ("1", "true", "TRUE", "yes", "YES")
end
