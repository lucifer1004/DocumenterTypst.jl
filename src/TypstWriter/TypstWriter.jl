"""
A module for rendering `Document` objects to Typst and PDF.

# Keywords

[`TypstWriter`](@ref) uses the following additional keyword arguments that can be passed to
`Documenter.makedocs`: `authors`, `sitename`.

**`sitename`** is the site's title displayed in the title bar and at the top of the
navigation menu. It goes into the Typst document title.

**`authors`** can be used to specify the authors. It goes into the Typst document metadata.

"""
module TypstWriter

import Documenter: Documenter
using Dates: Dates
using MarkdownAST: MarkdownAST, Node
using Typst_jll: typst as typst_exe
using pdfcpu_jll: pdfcpu
using Markdown: Markdown
using ANSIColoredPrinters: ANSIColoredPrinters

# Implement the Documenter runner interface for FormatSelector
import Documenter: Selectors, writer_supports_ansicolor

# ============================================================================
# TABLE OF CONTENTS
# ============================================================================
# 1. Configuration & Types         (this file)
# 2. Compilation Backends          (compilation.jl)
# 3. AST Conversion                (ast_conversion.jl)
# ============================================================================

# ============================================================================
# Path handling and anchor identification
# ============================================================================

"""
    escape_for_typst_string(s::String) -> String

Escape special characters for use inside Typst string literals.
Only backslash and double quote need to be escaped.

# Examples
```julia
escape_for_typst_string("test")                    # => "test"
escape_for_typst_string("test\\"quote\\"")           # => "test\\\\\\"quote\\\\\\""
escape_for_typst_string("C:\\\\\\\\path\\\\\\\\file.txt")  # => "C:\\\\\\\\\\\\\\\\path\\\\\\\\\\\\\\\\file.txt"
```
"""
function escape_for_typst_string(s::String)
    s = replace(s, "\\" => "\\\\")  # Backslash first
    s = replace(s, "\"" => "\\\"")  # Then double quote
    return s
end

"""
    remove_build_prefix(doc::Document, path::AbstractString) -> String

Remove the build directory prefix from a path.

# Examples
```julia
remove_build_prefix(doc, "build-typst/man/guide.md")  # => "man/guide.md"
remove_build_prefix(doc, "man/guide.md")              # => "man/guide.md"
```
"""
function remove_build_prefix(doc::Documenter.Document, path::AbstractString)
    build_prefix = doc.user.build * "/"
    if startswith(path, build_prefix)
        return path[(length(build_prefix) + 1):end]
    end
    return path
end

"""
    make_label_id(doc::Document, file::AbstractString, label::AbstractString) -> String

Generate a Typst label ID using the label() function syntax.
Returns the raw string (already escaped) ready to use in #label("...").

# Format
- Remove build prefix from file
- Combine as "file#label" (or just "label" if file is empty)
- Escape quotes and backslashes
- Returns string ready for: #label("...") and #link(label("..."))

# Examples
```julia
make_label_id(doc, "build-typst/man/guide.md", "Installation")
# => "man/guide.md#Installation"

make_label_id(doc, "build-typst/api.md", "Documenter.makedocs")
# => "api.md#Documenter.makedocs"

make_label_id(doc, "build-typst/cpp.md", "C++")
# => "cpp.md#C++"
```
"""
function make_label_id(
        doc::Documenter.Document, file::AbstractString, label::AbstractString
    )
    # Normalize path separators
    normalized_file = replace(file, "\\" => "/")

    # Remove build prefix
    path = remove_build_prefix(doc, normalized_file)

    # Combine file#label (or just label if path is empty)
    full_id = isempty(path) ? label : "$path#$label"

    # Escape for Typst string literal
    return escape_for_typst_string(full_id)
end

# ============================================================================
# Configuration
# ============================================================================

"""
    DocumenterTypst.Typst(; kwargs...)

Output format specifier that results in Typst/PDF output.
Used together with `Documenter.makedocs`, e.g.

```julia
makedocs(
    format = DocumenterTypst.Typst()
)
```

The `makedocs` argument `sitename` will be used for the document title.
The `authors` argument should also be specified and will be used for the document metadata.
A version number can be specified with the `version` option to `Typst`, which will be 
printed in the document and also appended to the output PDF file name.

# Keyword arguments

- **`platform`** sets the platform where the Typst file is compiled. Available options:
    - `"typst"` (default): Uses Typst_jll, a Julia binary wrapper that automatically 
      provides the Typst compiler across all platforms.
    - `"native"`: Uses the system-installed `typst` executable found in `PATH`, or 
      a custom path specified via the `typst` keyword argument.
    - `"none"`: Skips compilation and only generates the `.typ` source file in the 
      build directory.

- **`version`** specifies the version number printed on the title page of the manual.
  Defaults to the value in the `TRAVIS_TAG` environment variable (although this behaviour 
  is considered deprecated), or to an empty string if `TRAVIS_TAG` is unset.

- **`typst`** allows specifying a custom path to a `typst` executable. Only used when 
  `platform="native"`. Can be either a `String` path or a `Cmd` object.

- **`optimize_pdf`** enables automatic PDF optimization using pdfcpu after compilation.
  Defaults to `true`. When enabled, reduces PDF file size by 60-85% by compressing 
  uncompressed streams and optimizing PDF structure. Set to `false` to skip optimization 
  (e.g., for faster builds during development).

- **`use_system_fonts`** controls whether to allow Typst to use system fonts.
  Defaults to `true`. Setting to `false` will possibly decrease the size of the PDF file.

- **`font_paths`** specifies custom font directories for Typst to search.
  Defaults to `String[]` (empty). Provide a vector of directory paths to add custom fonts.
  Each path will be passed to Typst as `--font-path` argument.
"""
struct Typst <: Documenter.Writer
    platform::String
    version::String
    typst::Union{Cmd, String, Nothing}
    optimize_pdf::Bool
    use_system_fonts::Bool
    font_paths::Vector{String}
    function Typst(; platform = "typst", version = get(ENV, "TRAVIS_TAG", ""), typst = nothing, optimize_pdf = true, use_system_fonts = true, font_paths = String[])
        platform ∈ ("native", "typst", "none") ||
            throw(ArgumentError("unknown platform: $platform"))
        return new(platform, string(version), typst, optimize_pdf, use_system_fonts, font_paths)
    end
end

# Implement the writer interface for ANSI color support
writer_supports_ansicolor(::Typst) = false

# ============================================================================
# Helper functions copied from Documenter for .typ file support
# ============================================================================

"""
    lt_page_typst(a::AbstractString, b::AbstractString)

Checks if the page path `a` should come before `b` in a sorted list.
Copied from Documenter.Builder.lt_page.
"""
function lt_page_typst(a, b)
    a = endswith(a, "index.md") ? chop(a; tail = 8) : a
    b = endswith(b, "index.md") ? chop(b; tail = 8) : b
    return a < b
end

"""
    walk_navpages_typst(...)

Recursively walks through pages to generate NavNodes.
Copied from Documenter.Builder.walk_navpages to enable .typ file support.
"""
function walk_navpages_typst(visible, title, src, children, parent, doc)
    parent_visible = (parent === nothing) || parent.visible
    if src !== nothing
        src = normpath(src)
        src in keys(doc.blueprint.pages) || error("'$src' is not an existing page!")
    end
    nn = Documenter.NavNode(src, title, parent)
    (src === nothing) || push!(doc.internal.navlist, nn)
    nn.visible = parent_visible && visible
    nn.children = walk_navpages_typst(children, nn, doc)
    return nn
end

function walk_navpages_typst(hps::Tuple, parent, doc)
    @assert length(hps) == 4
    return walk_navpages_typst(hps..., parent, doc)
end

walk_navpages_typst(title::String, children::Vector, parent, doc) = walk_navpages_typst(true, title, nothing, children, parent, doc)
walk_navpages_typst(title::String, page, parent, doc) = walk_navpages_typst(true, title, page, [], parent, doc)

walk_navpages_typst(p::Pair, parent, doc) = walk_navpages_typst(p.first, p.second, parent, doc)
walk_navpages_typst(ps::Vector, parent, doc) = [walk_navpages_typst(p, parent, doc)::Documenter.NavNode for p in ps]
walk_navpages_typst(src::String, parent, doc) = walk_navpages_typst(true, nothing, src, [], parent, doc)

# ============================================================================
# Documenter integration hooks
# ============================================================================

# Hook into SetupBuildDirectory to handle .typ files
# We need to override this to add .typ files to doc.blueprint.pages
# This is necessary because Documenter only adds .md files by default
function _setup_build_directory_impl(doc::Documenter.Document)
    @info "SetupBuildDirectory: setting up build directory."

    # Frequently used fields.
    build = doc.user.build
    source = doc.user.source
    workdir = doc.user.workdir

    # The .user.source directory must exist.
    isdir(source) || error("source directory '$(abspath(source))' is missing.")

    # We create the .user.build directory.
    # If .user.clean is set, we first clean the existing directory.
    doc.user.clean && isdir(build) && rm(build; recursive = true)
    isdir(build) || mkpath(build)

    # We'll walk over all the files in the .user.source directory.
    # MODIFICATION: Also handle .typ files in addition to .md files
    mdpages = String[]
    for (root, dirs, files) in walkdir(source; follow_symlinks = true)
        for dir in dirs
            d = normpath(joinpath(build, relpath(root, source), dir))
            isdir(d) || mkdir(d)
        end
        for file in files
            src = normpath(joinpath(root, file))
            dst = normpath(joinpath(build, relpath(root, source), file))

            if workdir == :build
                wd = normpath(joinpath(build, relpath(root, source)))
            elseif workdir isa Symbol
                throw(ArgumentError("Unrecognized working directory option '$workdir'"))
            else
                wd = normpath(joinpath(doc.user.root, workdir))
            end

            # MODIFICATION: Handle both .md and .typ files
            if endswith(file, ".md")
                push!(mdpages, Documenter.srcpath(source, root, file))
                Documenter.addpage!(doc, src, dst, wd)
            elseif endswith(file, ".typ")
                # Add .typ files to blueprint.pages so they can be referenced in pages
                Documenter.addpage!(doc, src, dst, wd)
                cp(src, dst; force = true)
            else
                cp(src, dst; force = true)
            end
        end
    end

    # If the user hasn't specified the page list, use markdown files only
    userpages = isempty(doc.user.pages) ? sort(mdpages, lt = lt_page_typst) : doc.user.pages

    # Populating the .navtree and .navlist.
    for navnode in walk_navpages_typst(userpages, nothing, doc)
        push!(doc.internal.navtree, navnode)
    end

    # Finally we populate the .next and .prev fields
    local prev::Union{Documenter.NavNode, Nothing} = nothing
    for navnode in doc.internal.navlist
        navnode.prev = prev
        if prev !== nothing
            prev.next = navnode
        end
        prev = navnode
    end

    # If the user specified pagesonly, remove unlisted pages
    if doc.user.pagesonly
        navlist_pages = getfield.(doc.internal.navlist, :page)
        for page in keys(doc.blueprint.pages)
            page ∈ navlist_pages || delete!(doc.blueprint.pages, page)
        end
    end
    return
end

function _format_selector_impl(fmt::Typst, doc::Documenter.Document)
    return TypstWriter.render(doc, fmt)
end

# ============================================================================
# Runtime initialization - override Documenter methods
# ============================================================================

"""
    __init__()

Initialize the TypstWriter module at runtime.

This function overrides Documenter's methods to support .typ file handling and
Typst format selection. Method overriding is done at runtime to allow precompilation
of the rest of the module.
"""
function __init__()
    # Override SetupBuildDirectory to handle .typ files in addition to .md files
    @eval Documenter.Selectors.runner(
        ::Type{Documenter.Builder.SetupBuildDirectory},
        doc::Documenter.Document
    ) = TypstWriter._setup_build_directory_impl(doc)

    # Override FormatSelector to enable Typst format
    return @eval Documenter.Selectors.runner(
        ::Type{Documenter.FormatSelector},
        fmt::TypstWriter.Typst,
        doc::Documenter.Document
    ) = TypstWriter._format_selector_impl(fmt, doc)
end

# ============================================================================
# Rendering state and context
# ============================================================================

"""
    RenderState

Immutable global state built once at the start of rendering.
Contains lookup tables and cached values that don't change during the rendering process.
"""
struct RenderState
    lowercase_anchors::Dict{String, String}  # lowercase key -> original label
    build_path::String  # Pre-normalized build path (for performance)
end

"""
    Context{I<:IO}

Mutable rendering context that changes as we traverse the document.
Implements the IO interface for convenient printing.
"""
mutable struct Context{I <: IO} <: IO
    io::I
    doc::Documenter.Document
    state::RenderState

    # Current file state
    filename::String  # Currently active source file
    depth::Int        # Current heading depth
    in_header::Bool   # Are we inside a header?
    in_block::Bool    # Are we inside a block container (admonition, blockquote, etc)?

    # Per-page state (reset for each page)
    footnote_defs::Dict{String, Node}  # Footnote id -> definition node
end

function Context(io::I, doc::Documenter.Document, state::RenderState) where {I <: IO}
    return Context{I}(io, doc, state, "", 1, false, false, Dict())
end

_print(c::Context, args...) = Base.print(c.io, args...)
_println(c::Context, args...) = Base.println(c.io, args...)

# ============================================================================
# Path utilities using RenderState
# ============================================================================

"""
    with_build_prefix(state::RenderState, relative_path::AbstractString) -> String

Add build prefix to relative paths using cached build_path from RenderState.
Optimized to avoid repeated normalization of the build path.
"""
function with_build_prefix(state::RenderState, relative_path::AbstractString)
    rel_path = replace(relative_path, "\\" => "/")
    return state.build_path * "/" * rel_path
end

# ============================================================================
# Utilities
# ============================================================================

"""
    collect_footnotes!(defs::Dict{String,Node}, node::Node) -> Dict{String,Node}

Recursively collect all footnote definitions from an AST.

Handles both regular AST nodes and special cases like `DocsNode`, which contains
separate AST trees in its `mdasts` field that need to be scanned independently.
"""
function collect_footnotes!(defs::Dict{String, Node}, node::Node)
    if node.element isa MarkdownAST.FootnoteDefinition
        defs[node.element.id] = node
    end

    # Special handling for DocsNode which contains separate ASTs in .mdasts
    # These ASTs are not in node.children, so we must scan them explicitly
    if node.element isa Documenter.DocsNode
        for docstringast in node.element.mdasts
            collect_footnotes!(defs, docstringast)
        end
    end

    for child in node.children
        collect_footnotes!(defs, child)
    end
    return defs
end

const STYLE = joinpath(dirname(@__FILE__), "..", "..", "assets", "documenter.typ")

const DOCUMENT_STRUCTURE = (
    "part", "chapter", "section", "subsection", "subsubsection", "paragraph", "subparagraph",
)

"""
    build_anchor_lookup(doc::Document) -> Dict{String,String}

Build a case-insensitive anchor lookup map.

Returns a dictionary mapping lowercase keys (file#label) to original anchor labels.
This allows case-insensitive matching of anchor references while preserving the
original case for label generation.

# Implementation
Iterates through all anchors in doc.internal.headers.map and creates entries
using normalized paths and anchor labels (which include -nth suffixes for uniqueness).

Optimized to minimize function calls and string operations.
"""
function build_anchor_lookup(doc::Documenter.Document)
    lookup = Dict{String, String}()

    for (_, filedict) in doc.internal.headers.map
        for (file, anchors) in filedict
            # Normalize file path once per file
            normalized_file = replace(file, "\\" => "/")
            for anchor in anchors
                # Get label once per anchor
                label = Documenter.anchor_label(anchor)
                # Build key directly without intermediate allocations
                key = normalized_file * "#" * lowercase(label)
                lookup[key] = label
            end
        end
    end

    return lookup
end

"""
    include_typst_file(context::Context, title::AbstractString, depth::Int)

Include a pure Typst file using #include directive with automatic heading level adjustment.

Uses Typst's `offset` parameter to adjust heading levels and `#include` to preserve
relative paths for images and other resources.

# Arguments
- `context::Context`: The rendering context
- `title::AbstractString`: The chapter/section title from pages config (can be empty)
- `depth::Int`: The nesting depth in the pages configuration

# Implementation Details
- Validates source file existence before rendering
- Calculates heading offset: `depth + (has_title ? 1 : 0) - 1`
- Generates a scoped block with `set heading(offset: N)`
- Uses `#include "path"` to maintain file's relative path context
"""
function include_typst_file(context::Context, title::AbstractString, depth::Int)
    # Verify source file exists
    src_path = joinpath(context.doc.user.root, context.doc.user.source, context.filename)
    if !isfile(src_path)
        error("Typst file not found: $(src_path)")
    end

    # Insert chapter/section title if provided
    if !isempty(title) && depth <= length(DOCUMENT_STRUCTURE)
        _println(context, "#extended_heading(level: $(depth), [$(title)])\n")
    end

    # Calculate heading offset
    # depth: position in pages hierarchy
    # +1 if title exists (title itself occupies one level)
    # -1 because .typ uses = for level 1, but offset starts from 0
    heading_offset = depth + (isempty(title) ? 0 : 1) - 1
    include_path = replace(context.filename, "\\" => "/")
    return _println(context, "#extended_include(\"$(include_path)\", offset: $(heading_offset))")
end

# ============================================================================
# Main rendering engine
# ============================================================================

function render(doc::Documenter.Document, settings::Typst = Typst())
    return mktempdir() do path
        cp(joinpath(doc.user.root, doc.user.build), joinpath(path, "build"))
        cd(joinpath(path, "build")) do
            fileprefix = typst_fileprefix(doc, settings)

            # Phase 1: AST to Typst conversion
            @info "TypstWriter: converting Documenter AST to Typst..."
            typst_time = @elapsed begin
                open("$(fileprefix).typ", "w") do io
                    # Build global rendering state with cached build path
                    build_path = replace(doc.user.build, "\\" => "/")
                    state = RenderState(build_anchor_lookup(doc), build_path)
                    context = Context(io, doc, state)

                    writeheader(context, doc, settings)
                    for (title, filename, depth) in files(doc.user.pages)
                        context.filename = filename
                        empty!(context.footnote_defs)
                        if 1 <= depth <= length(DOCUMENT_STRUCTURE)
                            header_text = "#extended_heading(level: $(depth), [$(title)])\n"
                            if isempty(filename)
                                _println(context, header_text)
                            elseif endswith(filename, ".typ")
                                # New path: include pure Typst files
                                include_typst_file(context, title, depth)
                            else
                                # Existing path: process Markdown files
                                path = normpath(filename)
                                page = doc.blueprint.pages[path]
                                if get(page.globals.meta, :IgnorePage, :none) !== :Typst
                                    # Pre-scan to collect footnote definitions
                                    collect_footnotes!(context.footnote_defs, page.mdast)

                                    context.depth = depth + (isempty(title) ? 0 : 1)
                                    context.depth > depth && _println(context, header_text)
                                    typst_toplevel(context, page.mdast.children)
                                end
                            end
                        end
                    end
                    writefooter(context, doc)
                end
                cp(STYLE, "documenter.typ")
            end
            @info "TypstWriter: AST conversion completed." time = "$(round(typst_time; digits = 2))s"

            # Phase 2 & 3: Typst compilation (and optimization if enabled)
            status = compile_typ(doc, settings, fileprefix)

            # Debug: if DOCUMENTER_TYPST_DEBUG environment variable is set, copy the Typst
            # source files over to a directory under doc.user.root.
            if haskey(ENV, "DOCUMENTER_TYPST_DEBUG")
                dst = if isempty(ENV["DOCUMENTER_TYPST_DEBUG"])
                    mktempdir(doc.user.root; cleanup = false)
                else
                    joinpath(doc.user.root, ENV["DOCUMENTER_TYPST_DEBUG"])
                end
                sources = cp(pwd(), dst; force = true)
                @info "Typst sources copied for debugging to $(sources)"
            end

            # If the build was successful, copy the PDF or the Typst source to the .build directory
            if status && (settings.platform != "none")
                pdffile = "$(fileprefix).pdf"
                cp(pdffile, joinpath(doc.user.root, doc.user.build, pdffile); force = true)
            elseif status && (settings.platform == "none")
                cp(pwd(), joinpath(doc.user.root, doc.user.build); force = true)
            else
                error("Compiling the .typ file failed. See logs for more information.")
            end
        end
    end
end

function typst_fileprefix(doc::Documenter.Document, settings::Typst)
    fileprefix = doc.user.sitename
    if occursin(Base.VERSION_REGEX, settings.version)
        v = VersionNumber(settings.version)
        fileprefix *= "-$(v.major).$(v.minor).$(v.patch)"
    end
    return replace(fileprefix, " " => "")
end

function writeheader(io::IO, doc::Documenter.Document, settings::Typst)
    custom = joinpath(doc.user.root, doc.user.source, "assets", "custom.typ")

    # Read custom.typ content to embed directly (instead of using #include)
    # This ensures that #let config definitions are in the correct scope
    custom_content = if isfile(custom)
        read(custom, String)
    else
        "// No custom.typ found\n"
    end

    preamble = """
    // Import templates

    #import("documenter.typ"): *

    // Custom styling and content
    // Embedded directly to ensure proper scoping of #let definitions

    $(custom_content)

    // Useful variables

    #show: doc => documenter(
        title: [$(doc.user.sitename)],
        date: [$(Dates.format(Dates.now(), "u d, Y"))],
        version: [$(settings.version)],
        authors: [$(doc.user.authors)],
        julia-version: [$(VERSION)],
        config: config,
        doc,
    )
    """

    # output preamble
    return _println(io, preamble)
end

function writefooter(io::IO, doc::Documenter.Document) end

# ============================================================================
# Page structure helpers
# ============================================================================

function files!(out::Vector, v::Vector, depth)
    for each in v
        files!(out, each, depth + 1)
    end
    return out
end

# Tuples come from `hide(page)` with either
# (visible, nothing,    page,         children) or
# (visible, page.first, pages.second, children)
function files!(out::Vector, v::Tuple, depth)
    files!(out, isnothing(v[2]) ? v[3] : v[2] => v[3], depth)
    return files!(out, v[4], depth)
end

files!(out, s::AbstractString, depth) = push!(out, ("", s, depth))

function files!(out, p::Pair{<:AbstractString, <:Any}, depth)
    # Hack time. Because of Julia's typing, something like
    # `"Introduction" => "index.md"` may get typed as a `Pair{String,Any}`!
    if p[2] isa AbstractString
        push!(out, (p.first, p.second, depth))
    else
        push!(out, (p.first, "", depth))
        files!(out, p.second, depth)
    end
    return out
end

files(v::Vector) = files!(Tuple{String, String, Int}[], v, 0)

# ============================================================================
# Include submodules
# ============================================================================

include("compilation.jl")
include("ast_conversion.jl")

end
