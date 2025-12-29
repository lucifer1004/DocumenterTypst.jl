# ============================================================================
# Test Helper Functions
# ============================================================================
#
# Shared utilities for DocumenterTypst tests.
# These functions are used across multiple test files.

"""
    render_to_typst(markdown::String; sitename="Test", pages=["index.md"]) -> String

Render markdown to Typst and return the body content (without preamble).
This is the core testing primitive for verifying Typst output.

# Example
```julia
output = render_to_typst("Hello **world**!")
@test contains(output, "#strong([world])")
```
"""
function render_to_typst(markdown::String; sitename = "Test", pages = ["index.md"])
    return mktempdir() do dir
        srcdir = joinpath(dir, "src")
        mkpath(srcdir)
        write(joinpath(srcdir, "index.md"), markdown)

        makedocs(;
            root = dir,
            source = "src",
            build = "build",
            sitename = sitename,
            format = DocumenterTypst.Typst(; platform = "none"),
            pages = pages,
            doctest = false,
            remotes = nothing,
        )

        # Read generated .typ file
        typfile = joinpath(dir, "build", "$(replace(sitename, " " => "")).typ")
        content = read(typfile, String)

        # Extract body (skip preamble)
        return extract_typst_body(content)
    end
end

"""
    extract_typst_body(content::String) -> String

Extract the body content from a Typst file, removing the preamble.
"""
function extract_typst_body(content::String)
    lines = split(content, '\n')

    # Find where preamble ends (look for closing paren of documenter(...))
    preamble_end = findfirst(i -> strip(lines[i]) == ")", eachindex(lines))
    body_start = preamble_end === nothing ? 1 : preamble_end + 1

    # Skip empty lines after preamble
    while body_start <= length(lines) && isempty(strip(lines[body_start]))
        body_start += 1
    end

    return join(lines[body_start:end], '\n')
end
