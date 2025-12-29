# ============================================================================
# AST to Typst conversion
# ============================================================================
#
# This module contains all the typst() methods that convert MarkdownAST nodes
# and Documenter-specific nodes to Typst markup.
#
# The main entry point is typst(io::Context, node::Node) which dispatches
# to specialized methods based on the node type.

# A few of the nodes are printed differently depending on whether they appear
# as the top-level blocks of a page, or somewhere deeper in the AST.
istoplevel(n::Node) = !isnothing(n.parent) && isa(n.parent.element, MarkdownAST.Document)

"""
    typst(io::Context, node::Node)

Main entry point for converting MarkdownAST nodes to Typst markup.

Dispatches to specialized methods based on the node's element type using
Julia's multiple dispatch. If no specialized method exists for a node type,
throws an error indicating the type is not implemented.

# Implementation Pattern

To add support for a new node type, define a method with the signature:

```julia
function typst(io::Context, node::Node, element::YourNodeType)
    # Convert element to Typst markup
    # Use _print() and _println() to write to io
    # Recursively call typst() for child nodes
end
```

# Examples

The 50+ `typst()` methods in this file implement conversions for all
Documenter and MarkdownAST node types. See individual method implementations
for specific conversion logic.
"""
typst(io::Context, node::Node) = typst(io, node, node.element)
typst(io::Context, node::Node, e) = error("$(typeof(e)) not implemented: $e")

# Render children
function typst(io::Context, children)
    @assert eltype(children) <: MarkdownAST.Node
    for node in children
        typst(io, node)
    end
    return nothing
end

"""
    typst_toplevel(io::Context, children)

Render top-level document blocks with appropriate vertical spacing.

Adds blank lines before and after most block elements (paragraphs, code blocks,
lists, tables, etc.) to improve readability of the generated `.typ` file and
ensure proper spacing in the final PDF output.

Certain element types (headers, docstrings, metadata nodes) defined in
`NoExtraTopLevelNewlines` are rendered without extra spacing to avoid
unwanted visual gaps in the document structure.

# Usage

- Use `typst_toplevel()` for direct children of document root or page sections
- Use regular `typst()` for nested content (inside lists, quotes, etc.)
"""
function typst_toplevel(io::Context, children)
    @assert eltype(children) <: MarkdownAST.Node
    for node in children
        otherelement = !isa(node.element, NoExtraTopLevelNewlines)
        otherelement && _println(io)
        typst(io, node)
        otherelement && _println(io)
    end
    return nothing
end

const NoExtraTopLevelNewlines = Union{
    Documenter.AnchoredHeader,
    Documenter.ContentsNode,
    Documenter.DocsNode,
    Documenter.DocsNodesBlock,
    Documenter.EvalNode,
    Documenter.IndexNode,
    Documenter.MetaNode,
}

function typst(io::Context, node::Node, ah::Documenter.AnchoredHeader)
    anchor = ah.anchor
    label_id = make_label_id(io.doc, anchor.file, Documenter.anchor_label(anchor))
    if istoplevel(node)
        typst_toplevel(io, node.children)
    else
        typst(io, node.children)
    end
    return _println(io, " #label(\"", label_id, "\")\n")
end

## Documentation Nodes.

function typst(io::Context, node::Node, ::Documenter.DocsNodesBlock)
    return if istoplevel(node)
        typst_toplevel(io, node.children)
    else
        typst(io, node.children)
    end
end

function typst(io::Context, node::Node, docs::Documenter.DocsNode)
    node, ast = docs, node
    label_id = make_label_id(io.doc, node.anchor.file, Documenter.anchor_label(node.anchor))
    # Docstring header based on the name of the binding and it's category.
    _print(io, "#raw(\"")
    typstescstr(io, string(node.object.binding))
    _print(io, "\", block: false) #label(\"", label_id, "\")")
    _println(io, " -- ", Documenter.doccat(node.object), ".\n")
    # Body. May contain several concatenated docstrings.
    _println(io, "#grid(columns: (2em, 1fr), [], [")
    typstdoc(io, ast)
    return _println(io, "])")
end

"""
    typstdoc(io::Context, node::Node)

Render the body of a docstring node, including all concatenated docstrings and source links.

The `node.element.results` field contains a vector of `Docs.DocStr` objects associated with
each markdown object, providing metadata such as file and line info needed for generating
correct source links.
"""
function typstdoc(io::Context, node::Node)
    @assert node.element isa Documenter.DocsNode
    for (docstringast, result) in zip(node.element.mdasts, node.element.results)
        _println(io)
        typst(io, docstringast.children)
        _println(io)
        # When a source link is available then print the link.
        url = Documenter.source_url(io.doc, result)
        if url !== nothing
            link = "#link(\"$url\")[`source`]"
            _println(io, "\n", link, "\n")
        end
    end
    return nothing
end

## Index, Contents, and Eval Nodes.

function typst(io::Context, ::Node, index::Documenter.IndexNode)
    # Having an empty itemize block in Typst throws an error, so we bail early
    # in that situation:
    isempty(index.elements) && (_println(io); return nothing)

    _println(io, "\n")
    for (object, doc, _, _, _) in index.elements
        # doc is a DocsNode with an anchor field!
        label_id = make_label_id(
            io.doc, doc.anchor.file, Documenter.anchor_label(doc.anchor)
        )
        text = string(object.binding)
        _print(io, "- #link(label(\"")
        _print(io, label_id, "\"))[#raw(\"")
        typstescstr(io, text)
        _println(io, "\", block: false)]")
    end
    return _println(io, "\n")
end

function typst(io::Context, ::Node, contents::Documenter.ContentsNode)
    # Having an empty itemize block in LaTeX throws an error, so we bail early
    # in that situation:
    isempty(contents.elements) && (_println(io); return nothing)

    depth = 1
    for (count, path, anchor) in contents.elements
        @assert length(anchor.node.children) == 1
        header = first(anchor.node.children)
        level = header.element.level
        # Filter out header levels smaller than the requested mindepth
        level = level - contents.mindepth + 1
        level < 1 && continue

        if level > depth
            for k in 1:(level - depth)
                # if we jump by more than one level deeper we need to put empty bullets to take that level
                (k >= 2) && _println(io, repeat(" ", 2 * (depth + k - 1)), "-")
                depth += 1
            end
        end

        # Print the corresponding item
        label_id = make_label_id(io.doc, anchor.file, Documenter.anchor_label(anchor))
        _print(io, repeat(" ", 2 * (level - 1)), "- #link(label(\"", label_id, "\"))[")
        typst(io, header.children)
        _println(io, "]")
    end
    return nothing
end

function typst(io::Context, node::Node, evalnode::Documenter.EvalNode)
    return if evalnode.result !== nothing
        typst_toplevel(io, evalnode.result.children)
    end
end

# Select the "best" representation for Typst output.
using Base64: base64decode
typst(io::Context, node::Node, ::Documenter.MultiOutput) = typst(io, node.children)
function typst(io::Context, node::Node, moe::Documenter.MultiOutputElement)
    return Base.invokelatest(typst, io, node, moe.element)
end
function typst(io::Context, ::Node, d::Dict{MIME, Any})
    filename = String(rand('a':'z', 7))
    if haskey(d, MIME"image/png"())
        write("$(filename).png", base64decode(d[MIME"image/png"()]))
        _println(io, "#figure(image($(filename).png, width: 100%))")
    elseif haskey(d, MIME"image/jpeg"())
        write("$(filename).jpeg", base64decode(d[MIME"image/jpeg"()]))
        _println(io, "#figure(image($(filename).jpeg, width: 100%))")
    elseif haskey(d, MIME"text/markdown"())
        md = Markdown.parse(d[MIME"text/markdown"()])
        ast = MarkdownAST.convert(MarkdownAST.Node, md)
        typst(io, ast.children)
    elseif haskey(d, MIME"text/plain"())
        text = d[MIME"text/plain"()]
        out = repr(MIME"text/plain"(), ANSIColoredPrinters.PlainTextPrinter(IOBuffer(text)))
        # We set a "fake" language as text/plain so that the writer knows how to
        # deal with it.
        codeblock = MarkdownAST.CodeBlock("text/plain", out)
        typst(io, MarkdownAST.Node(codeblock))
    else
        error("this should never happen.")
    end
    return nothing
end

## Basic Nodes. AKA: any other content that hasn't been handled yet.

function typst(io::Context, node::Node, heading::MarkdownAST.Heading)
    N = heading.level
    level = min(io.depth + N - 1, length(DOCUMENT_STRUCTURE))
    _print(io, "#heading(level: $(level), [")
    io.in_header = true
    typst(io, node.children)
    io.in_header = false
    return _println(io, "])")
end

function typst(io::Context, ::Node, code::MarkdownAST.CodeBlock)
    # Check for native Typst math BEFORE calling codelang
    # because codelang only extracts the first word
    if code.info == "math typst"
        # Render a native Typst math block
        _println(io)
        _println(io, "\$")
        _println(io, code.code)
        _println(io, "\$")
        _println(io)
        return nothing
    end

    language = Documenter.codelang(code.info)
    if language == "julia-repl" || language == "@repl"
        language = "julia"
    elseif language == "text/plain" || isempty(language)
        language = "text"
    end
    text = IOBuffer(code.code)
    code_code = repr(MIME"text/plain"(), ANSIColoredPrinters.PlainTextPrinter(text))
    _println(io)
    _print(io, "#raw(\"")
    typstescstr(io, code_code)
    _println(io, "\", block: true, lang: \"$(language)\")")
    return nothing
end

function typst(io::Context, node::Node, ::Documenter.MultiCodeBlock)
    return typst(io, node, join_multiblock(node))
end
function join_multiblock(node::Node)
    @assert node.element isa Documenter.MultiCodeBlock
    io = IOBuffer()
    codeblocks = [n.element::MarkdownAST.CodeBlock for n in node.children]
    for (i, thing) in enumerate(codeblocks)
        print(io, thing.code)
        if i != length(codeblocks)
            println(io)
            if findnext(x -> x.info == node.element.language, codeblocks, i + 1) == i + 1
                println(io)
            end
        end
    end
    return MarkdownAST.CodeBlock(node.element.language, String(take!(io)))
end

function typst(io::Context, ::Node, code::MarkdownAST.Code)
    _print(io, " #raw(\"")
    typstescstr(io, code.code)
    return _print(io, "\", block: false) ")
end

function typst(io::Context, node::Node, ::MarkdownAST.Paragraph)
    typst(io, node.children)
    # In block containers (quotes, admonitions, list items), use single newline
    # Outside blocks, use double newline for paragraph separation
    return io.in_block ? _println(io) : _println(io, "\n")
end

function typst(io::Context, node::Node, ::MarkdownAST.BlockQuote)
    _println(io, "#quote[")
    old_in_block = io.in_block
    io.in_block = true
    typst(io, node.children)
    io.in_block = old_in_block
    return _println(io, "]")
end

function typst(io::Context, node::Node, md::MarkdownAST.Admonition)
    type = "default"
    if md.category in ("danger", "warning", "note", "info", "tip", "compat")
        type = md.category
    end

    _println(io, "#admonition(type: \"$type\", title: \"$(md.title)\")[")
    old_in_block = io.in_block
    io.in_block = true
    typst(io, node.children)
    io.in_block = old_in_block
    _println(io, "]")
    return nothing
end

"""
    typst(::Context, ::Node, ::MarkdownAST.FootnoteDefinition)

No-op for footnote definitions.

Footnote definitions are collected during the pre-scan phase and rendered inline at
FootnoteLink sites, so we don't output anything here to avoid duplication.
"""
function typst(::Context, ::Node, ::MarkdownAST.FootnoteDefinition)
    return nothing
end

function typst(io::Context, node::Node, list::MarkdownAST.List)
    return typst_list(io, node, list, 0)
end

"""
    typst_list(io::Context, node::Node, list::MarkdownAST.List, depth::Int)

Recursively render nested lists with proper indentation and bullet symbols.

Handles both ordered lists (`+` in Typst) and unordered lists (`-` in Typst),
automatically managing:
- Indentation levels (2 spaces per depth)
- Bullet/numbering symbols based on list type
- The `in_block` state to control paragraph spacing within list items
- Recursive nesting for multi-level lists

# Arguments
- `io::Context`: Rendering context
- `node::Node`: The list node containing list items as children
- `list::MarkdownAST.List`: The list element (contains type info)
- `depth::Int`: Current nesting depth (0 = top level)

# Implementation Notes

List items may contain mixed content (paragraphs, code blocks, nested lists).
The function preserves `in_block` state to ensure single-line spacing for
content within list items, while allowing nested lists to manage their own
indentation recursively.
"""
function typst_list(io::Context, node::Node, list::MarkdownAST.List, depth::Int)
    symbol = list.type === :ordered ? '+' : '-'
    indent = "  "^depth  # 2 spaces per depth level

    if depth == 0
        _println(io)
    end

    for item in node.children
        _print(io, indent, symbol, " ")

        # Set in_block to control paragraph spacing in list items
        old_in_block = io.in_block
        io.in_block = true

        # Process children of the item
        for (i, child) in enumerate(item.children)
            if child.element isa MarkdownAST.List
                # Nested list
                _println(io)
                typst_list(io, child, child.element, depth + 1)
            else
                # Regular content
                if i > 1
                    _print(io, indent, "  ")  # Continuation indent
                end
                typst(io, child)
            end
        end

        io.in_block = old_in_block
    end

    _println(io)

    return nothing
end

function typst(io::Context, ::Node, ::MarkdownAST.ThematicBreak)
    return _println(io, "#line(length: 100%)")
end

function typst(io::Context, ::Node, math::MarkdownAST.DisplayMath)
    _println(io)
    escaped_math = escape_for_typst_string(math.math)
    _print(io, "#mitex(\"")
    _print(io, escaped_math)
    _println(io, "\")")
    return _println(io)
end

function typst(io::Context, node::Node, table::MarkdownAST.Table)
    rows = MarkdownAST.tablerows(node)
    cols = length(table.spec)
    _println(io, "#align(center)[")
    _println(io, "#table(")
    # Use fractional units (1fr) to enable text wrapping in table cells
    _println(io, "columns: (", repeat("1fr,", cols), "),")
    _println(io, "align: (x, y) => ($(join(string.(table.spec), ",")),).at(x),")
    old_in_block = io.in_block
    io.in_block = true
    for (i, row) in enumerate(rows)
        for (j, cell) in enumerate(row.children)
            _print(io, " [")
            typst(io, cell.children)
            _print(io, "],")
        end
        _println(io)
    end
    io.in_block = old_in_block
    return _println(io, ")]")
end

function typst(io::Context, ::Node, raw::Documenter.RawNode)
    return if raw.name === :typst || raw.name === :typ
        _println(io, "\n", raw.text, "\n")
    else
        nothing
    end
end

# Inline Elements.

function typst(io::Context, ::Node, e::MarkdownAST.Text)
    return typstesc(io, e.text)
end

function typst(io::Context, node::Node, ::MarkdownAST.Strong)
    _print(io, "#strong([")
    typst(io, node.children)
    return _print(io, "])")
end

function typst(io::Context, node::Node, ::MarkdownAST.Emph)
    _print(io, "#emph([")
    typst(io, node.children)
    return _print(io, "])")
end

"""
    typst(io::Context, node::Node, image::MarkdownAST.Image)

Render a Markdown image as a Typst figure with centered alignment.

# Accessibility Notes

This implementation does NOT generate the `alt` parameter for figures because:
1. The caption already provides an accessible description that screen readers will read
2. In Markdown `![text](url)`, the text becomes the caption - duplicating it to `alt` causes redundancy
3. Per W3C guidelines, figures with descriptive captions don't need separate alt text
4. The `image.title` field is also unused because Julia's Markdown parser doesn't support
   the `![alt](url "title")` syntax, and even if it did, HTML's title attribute is a hover
   tooltip with no equivalent in PDF
"""
function typst(io::Context, node::Node, image::MarkdownAST.Image)
    _println(io, "#align(center)[")
    _println(io, "#figure(")
    _println(io, "image(")

    url = if Documenter.isabsurl(image.destination)
        @warn "images with absolute URLs not supported in Typst output in $(Documenter.locrepr(io.filename))" url = image.destination
        image.destination
    elseif startswith(image.destination, '/')
        # URLs starting with a / are assumed to be relative to the document's root
        normpath(lstrip(image.destination, '/'))
    else
        normpath(joinpath(dirname(io.filename), image.destination))
    end

    url = replace(url, "\\" => "/")

    _print(io, "\"", url, "\", ")
    _println(io, "width: 100%, fit: \"contain\"),")
    _println(io, "caption: [")
    old_in_block = io.in_block
    io.in_block = true
    typst(io, node.children)
    io.in_block = old_in_block
    return _println(io, "])]")
end

function typst(io::Context, node::Node, image::Documenter.LocalImage)
    # LocalImage is similar to MarkdownAST.Image but uses .path instead of .destination
    _println(io, "#align(center)[")
    _println(io, "#figure(")
    _println(io, "image(")

    # Normalize path (convert backslashes to forward slashes for Typst)
    url = replace(image.path, "\\" => "/")

    _print(io, "\"", url, "\", ")
    _println(io, "width: 100%, fit: \"contain\"),")
    _println(io, "caption: [")
    old_in_block = io.in_block
    io.in_block = true
    typst(io, node.children)
    io.in_block = old_in_block
    return _println(io, "])]")
end

function typst(io::Context, ::Node, f::MarkdownAST.FootnoteLink)
    # Look up the footnote definition
    return if haskey(io.footnote_defs, f.id)
        def_node = io.footnote_defs[f.id]
        _print(io, "#footnote[")
        old_in_block = io.in_block
        io.in_block = true
        # Render the footnote content inline
        # If the content is a single paragraph, render its children directly to avoid extra newlines
        if length(def_node.children) == 1 &&
                first(def_node.children).element isa MarkdownAST.Paragraph
            typst(io, first(def_node.children).children)
        else
            typst(io, def_node.children)
        end
        io.in_block = old_in_block
        _print(io, "]")
    else
        # Footnote definition not found - output a warning marker
        @warn "Footnote definition not found for [^$(f.id)] in $(Documenter.locrepr(io.filename))"
        _print(io, "#footnote[Missing footnote: $(f.id)]")
    end
end

# PageLink - internal cross-reference links resolved by Documenter
function typst(io::Context, node::Node, link::Documenter.PageLink)
    # PageLink represents a resolved @ref link or # same-file reference
    pagekey = Documenter.pagekey(io.doc, link.page)
    full_path = with_build_prefix(io.state, pagekey)

    if link.fragment !== nothing && !isempty(link.fragment)
        # Link to specific anchor in page
        # Case-insensitive lookup: link.fragment might be lowercase, but we need actual case
        # The lowercase_anchors map key includes full build path: "build_path#lowercase_label"
        lookup_key = full_path * "#" * lowercase(link.fragment)
        anchor_label = get(io.state.lowercase_anchors, lookup_key, link.fragment)

        # Generate label ID using the new approach
        label_id = make_label_id(io.doc, full_path, anchor_label)
        _print(io, "#link(label(\"", label_id, "\"))[")
    else
        # Link to page without fragment - link to first heading if exists
        default_anchor = get(io.state.page_first_anchors, full_path, nothing)

        if !isnothing(default_anchor)
            # Page has headings, link to the first one
            label_id = make_label_id(io.doc, full_path, default_anchor)
            _print(io, "#link(label(\"", label_id, "\"))[")
        else
            # Page has no headings, use a page-level label
            # We'll generate a label like "path/to/file.md#page"
            label_id = make_label_id(io.doc, full_path, "__page__")
            _print(io, "#link(label(\"", label_id, "\"))[")
        end
    end
    typst(io, node.children)
    return _print(io, "]")
end

"""
    typst(io::Context, node::Node, link::MarkdownAST.Link)

Render a Markdown link as a Typst link or label reference.

# Behavior

Properly resolved internal links should already be converted to `PageLink` by the
cross-reference pipeline. If we encounter a `MarkdownAST.Link` with `.md#` or `#` patterns,
it's likely an external link or a manual override by the user, which we handle as best-effort.

# Link Title Handling

This implementation intentionally ignores the `link.title` field because:
1. In HTML, the title attribute is a hover tooltip, not an accessibility feature
2. W3C guidelines recommend against relying on title for conveying important information
3. PDF/Typst has no hover mechanism, and `link()` doesn't support an `alt` parameter
4. Screen readers inconsistently support the title attribute, and keyboard users can't access it
5. Link text itself should be descriptive for proper accessibility

If the title contains important context, it should be incorporated into the link text or
surrounding prose instead.
"""
function typst(io::Context, node::Node, link::MarkdownAST.Link)
    return if io.in_header
        typst(io, node.children)
    else
        # Check if it's an external URL first (before checking for .md#)
        # Use Documenter's isabsurl() which matches ^[[:alpha:]+-.]+://
        is_external_url = Documenter.isabsurl(link.destination)

        if !is_external_url && occursin(".md#", link.destination)
            # Cross-file reference: other.md#section or path/other.md#section
            file, target = split(link.destination, ".md#"; limit = 2)
            file = file * ".md"  # Add back the .md extension
            # Convert to full path with build prefix
            full_path = with_build_prefix(io.state, file)
            # Generate label ID
            label_id = make_label_id(io.doc, full_path, target)
            _print(io, "#link(label(\"", label_id, "\"))")
        elseif !is_external_url && startswith(link.destination, "#")
            # Same-file reference: #anchor-slug
            fragment = lstrip(link.destination, '#')
            # io.filename is relative path, need to add build prefix
            full_path = with_build_prefix(io.state, io.filename)
            # Case-insensitive lookup with full build path
            lookup_key = full_path * "#" * lowercase(fragment)
            anchor_label = get(io.state.lowercase_anchors, lookup_key, fragment)
            # Generate label ID
            label_id = make_label_id(io.doc, full_path, anchor_label)
            _print(io, "#link(label(\"", label_id, "\"))")
        else
            # External link or other format
            _print(io, "#link(\"", link.destination, "\")")
        end
        _print(io, "[")
        typst(io, node.children)
        _print(io, "]")
    end
end

function typst(io::Context, ::Node, math::MarkdownAST.InlineMath)
    escaped_math = escape_for_typst_string(math.math)
    return _print(io, "#mi(\"", escaped_math, "\")")
end

# Metadata Nodes get dropped from the final output for every format but are needed throughout
# rest of the build and so we just leave them in place and print a blank line in their place.
typst(io::Context, ::Node, ::Documenter.MetaNode) = _println(io, "\n")

# In the original AST, SetupNodes were just mapped to empty Markdown.MD() objects.
typst(::Context, ::Node, ::Documenter.SetupNode) = nothing

function typst(io::Context, ::Node, value::MarkdownAST.JuliaValue)
    ref_type = typeof(value.ref)
    ref_value = value.ref
    @warn string("Unexpected Julia interpolation of type ", ref_type, " in the Markdown.") value = ref_value
    return typstesc(io, string(ref_value))
end

# Line breaks and soft breaks
# Note: SoftBreak and Backslash nodes don't appear in Julia's standard Markdown conversions.
# - SoftBreak: represents a soft line break (single newline in source)
# - Backslash: represents a literal backslash character (\\) after escaping
# We implement them for completeness in case they're encountered from other Markdown parsers.
typst(io::Context, ::Node, ::MarkdownAST.LineBreak) = _println(io, "#linebreak()")
typst(io::Context, ::Node, ::MarkdownAST.SoftBreak) = _print(io, "#linebreak(weak: true)")  # Weak break - may or may not break
typst(io::Context, ::Node, ::MarkdownAST.Backslash) = _print(io, "\\\\")  # Literal backslash: need \\ in Typst to display \

# ============================================================================
# Character escaping utilities
# ============================================================================

const _typstescape_chars = Dict{Char, AbstractString}()
# Build escape map for Typst special characters
# Using Char literals instead of string with $ to avoid Documenter warnings
for ch in ['@', '#', '*', '_', '\\', '$', '/', '`', '<', '>']
    _typstescape_chars[ch] = string("\\", ch)
end

const _typstescape_chars_in_string = Dict{Char, AbstractString}()
for ch in ['"', '\\']
    _typstescape_chars_in_string[ch] = string("\\", ch)
end

# Escape characters in contents
typstesc(io, ch::AbstractChar) = _print(io, get(_typstescape_chars, ch, ch))

function typstesc(io, s::AbstractString)
    for ch in s
        typstesc(io, ch)
    end
    return nothing
end

function typstesc(s::AbstractString)
    io = IOBuffer()
    for ch in s
        print(io, get(_typstescape_chars, ch, ch))
    end
    return String(take!(io))
end

# Escape characters in string literals
typstescstr(io, ch::AbstractChar) = _print(io, get(_typstescape_chars_in_string, ch, ch))

function typstescstr(io, s::AbstractString)
    for ch in s
        typstescstr(io, ch)
    end
    return nothing
end

function typstescstr(s::AbstractString)
    io = IOBuffer()
    for ch in s
        print(io, get(_typstescape_chars_in_string, ch, ch))
    end
    return String(take!(io))
end
