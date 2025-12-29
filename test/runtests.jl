module TypstWriterTests

using Test
using Documenter
using DocumenterTypst
using Logging

# Suppress @info output during tests for cleaner output
Logging.disable_logging(Logging.Info)
using DocumenterTypst.TypstWriter:
    TypstWriter, escape_for_typst_string, typstesc,
    typstescstr, writer_supports_ansicolor

# ============================================================================
# Test Helpers
# ============================================================================

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
            remotes = nothing
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

# ============================================================================
# Unit Tests - Pure Functions (no makedocs dependencies)
# ============================================================================

@testset "Typst Backend" begin
    @testset "Utility Functions" begin
        @testset "escape_for_typst_string" begin
            @test escape_for_typst_string("test") == "test"
            @test escape_for_typst_string("test\"quote\"") == "test\\\"quote\\\""
            @test escape_for_typst_string("C:\\path\\file.txt") == "C:\\\\path\\\\file.txt"
            @test escape_for_typst_string("\\\\") == "\\\\\\\\"
            @test escape_for_typst_string("\"\"") == "\\\"\\\""
            # Edge cases
            @test escape_for_typst_string("") == ""
            @test escape_for_typst_string("no special chars") == "no special chars"
        end

        @testset "typstesc and typstescstr" begin
            # typstesc - for content
            # Using string() to avoid $ triggering Documenter warnings
            test_chars = string('@', '#', '*', '_', '\\', '$', '/', '`', '<', '>')
            expected_str = string('@', '#', '*', '_', '\\', '\\', '$', '/', '`', '<', '>')
            expected = string(
                '\\',
                '@',
                '\\',
                '#',
                '\\',
                '*',
                '\\',
                '_',
                '\\',
                '\\',
                '\\',
                '$',
                '\\',
                '/',
                '\\',
                '`',
                '\\',
                '<',
                '\\',
                '>'
            )
            @test typstesc(test_chars) == expected
            @test typstesc("normal text") == "normal text"
            @test typstesc("") == ""

            # typstescstr - for string literals (only escapes " and \)
            @test typstescstr("\"\\") == "\\\"\\\\"
            @test typstescstr(test_chars) == expected_str
            @test typstescstr("normal text") == "normal text"
            @test typstescstr("") == ""
        end
    end

    @testset "Format Options" begin
        @test DocumenterTypst.Typst(platform = "native").platform == "native"
        @test DocumenterTypst.Typst(platform = "typst").platform == "typst"
        @test DocumenterTypst.Typst(platform = "none").platform == "none"

        @test_throws ArgumentError DocumenterTypst.Typst(platform = "invalid")

        @test DocumenterTypst.Typst(version = "1.0.0").version == "1.0.0"
        @test DocumenterTypst.Typst().version == get(ENV, "TRAVIS_TAG", "")

        # Test ANSI color support
        @test writer_supports_ansicolor(DocumenterTypst.Typst()) == false
    end

    @testset "Compiler Selection" begin
        @test TypstWriter.get_compiler(DocumenterTypst.Typst(platform = "native")) isa
            TypstWriter.NativeCompiler
        @test TypstWriter.get_compiler(DocumenterTypst.Typst(platform = "typst")) isa
            TypstWriter.TypstJllCompiler
        @test TypstWriter.get_compiler(DocumenterTypst.Typst(platform = "none")) isa
            TypstWriter.NoOpCompiler
    end

    # ============================================================================
    # Precise AST Rendering Tests (using render_to_typst helper)
    # ============================================================================

    @testset "Precise AST Rendering" begin
        @testset "Inline Formatting" begin
            # Bold
            output = render_to_typst("**bold text**")
            @test strip(output) == "#strong([bold text])"

            # Italic
            output = render_to_typst("*italic text*")
            @test strip(output) == "#emph([italic text])"

            # Inline code
            output = render_to_typst("`inline code`")
            @test strip(output) == "#raw(\"inline code\", block: false)"

            # Combined formatting - exact structure verification
            output = render_to_typst("**bold** and *italic* and `code`")
            @test strip(output) ==
                "#strong([bold]) and #emph([italic]) and  #raw(\"code\", block: false)"
        end

        @testset "Headings" begin
            output = render_to_typst("# Level 1")
            @test strip(output) ==
                "#extended_heading(level: 1, [Level 1])\n\n #label(\"index.md#Level-1\")"

            output = render_to_typst("## Level 2")
            @test strip(output) ==
                "#extended_heading(level: 2, [Level 2])\n\n #label(\"index.md#Level-2\")"

            output = render_to_typst("### Level 3")
            @test strip(output) ==
                "#extended_heading(level: 3, [Level 3])\n\n #label(\"index.md#Level-3\")"
        end

        @testset "Paragraphs" begin
            output = render_to_typst("First paragraph.\n\nSecond paragraph.")
            @test strip(output) == "First paragraph.\n\n\n\nSecond paragraph."
        end

        @testset "Code Blocks" begin
            # Julia code - verify exact structure
            output = render_to_typst("```julia\nx = 1 + 1\n```")
            @test strip(output) == "#raw(\"x = 1 + 1\", block: true, lang: \"julia\")"

            # No language specified - defaults to text
            output = render_to_typst("```\nplain text\n```")
            @test strip(output) == "#raw(\"plain text\", block: true, lang: \"text\")"

            # julia-repl should map to julia
            output = render_to_typst("```julia-repl\njulia> 1+1\n```")
            @test strip(output) == "#raw(\"julia> 1+1\", block: true, lang: \"julia\")"
        end

        @testset "Math - LaTeX" begin
            # Display math
            output = render_to_typst("```math\n\\sum_{i=1}^n i\n```")
            @test strip(output) == "#mitex(\"\\\\sum_{i=1}^n i\")"

            # Inline math
            output = render_to_typst("Inline ``\\alpha + \\beta`` math")
            @test strip(output) == "Inline #mi(\"\\\\alpha + \\\\beta\") math"
        end

        @testset "Math - Native Typst" begin
            output = render_to_typst("```math typst\nsum_(i=1)^n i\n```")
            # Native Typst math block starts and ends with $
            @test contains(output, "sum_(i=1)^n i")
        end

        @testset "Lists" begin
            # Unordered list - compact (no blank lines between items)
            output = render_to_typst("- Item 1\n- Item 2\n- Item 3")
            @test strip(output) == "- Item 1\n- Item 2\n- Item 3"

            # Ordered list
            output = render_to_typst("1. First\n2. Second\n3. Third")
            @test strip(output) == "+ First\n+ Second\n+ Third"

            # Nested lists - verify exact structure with proper indentation
            output = render_to_typst("- Level 1\n    - Level 2\n        - Level 3")
            @test contains(output, "- Level 1")
            @test contains(output, "  - Level 2")
            @test contains(output, "    - Level 3")

            # Mixed list with content and nesting
            output = render_to_typst(
                "- Item with text\n    - Nested item\n- Another top item"
            )
            @test contains(output, "- Item with text")
            @test contains(output, "  - Nested item")
            @test contains(output, "- Another top item")

            # Edge case: Deep nesting (Markdown parser handles depth)
            # MarkdownAST will parse this according to actual indentation
            output = render_to_typst("- L1\n    - L2\n        - L3\n            - L4")
            @test contains(output, "- L1")
            @test contains(output, "  - L2")
            @test contains(output, "    - L3")
            @test contains(output, "      - L4")

            # Edge case: List with paragraph breaks
            output = render_to_typst("- Item 1\n\n  Paragraph in item 1\n- Item 2")
            @test contains(output, "- Item 1")
            @test contains(output, "Paragraph in item 1")
            @test contains(output, "- Item 2")

            # Edge case: Mixed ordered/unordered nesting
            output = render_to_typst(
                "1. First ordered\n    - Nested unordered\n2. Second ordered"
            )
            @test contains(output, "+ First ordered")
            @test contains(output, "  - Nested unordered")
            @test contains(output, "+ Second ordered")
        end

        @testset "Block Quote" begin
            output = render_to_typst("> This is a quote\n> Multiple lines")
            @test strip(output) == "#safe-block(inset: 10pt)[\nThis is a quote Multiple lines\n]"
        end

        @testset "Thematic Break" begin
            output = render_to_typst("Text above\n\n---\n\nText below")
            @test strip(output) == "Text above\n\n\n\n#line(length: 100%)\n\n\nText below"
        end

        @testset "Admonitions" begin
            # Test each known category with exact output
            output = render_to_typst("!!! note \"Title\"\n    Content")
            @test strip(output) ==
                "#admonition(type: \"note\", title: \"Title\")[\nContent\n]"

            output = render_to_typst("!!! warning \"Title\"\n    Content")
            @test strip(output) ==
                "#admonition(type: \"warning\", title: \"Title\")[\nContent\n]"

            output = render_to_typst("!!! danger \"Title\"\n    Content")
            @test strip(output) ==
                "#admonition(type: \"danger\", title: \"Title\")[\nContent\n]"

            output = render_to_typst("!!! info \"Title\"\n    Content")
            @test strip(output) ==
                "#admonition(type: \"info\", title: \"Title\")[\nContent\n]"

            output = render_to_typst("!!! tip \"Title\"\n    Content")
            @test strip(output) ==
                "#admonition(type: \"tip\", title: \"Title\")[\nContent\n]"

            output = render_to_typst("!!! compat \"Title\"\n    Content")
            @test strip(output) ==
                "#admonition(type: \"compat\", title: \"Title\")[\nContent\n]"

            # Unknown category should default to "default"
            output = render_to_typst("!!! custom \"Title\"\n    Content")
            @test strip(output) ==
                "#admonition(type: \"default\", title: \"Title\")[\nContent\n]"
        end

        @testset "Tables" begin
            output = render_to_typst(
                """
                | A | B | C |
                |---|---|---|
                | 1 | 2 | 3 |
                | 4 | 5 | 6 |
                """
            )
            # Verify table structure exists
            @test contains(output, "#table(")
            @test contains(output, "align(center)")
            @test contains(output, "columns:")
            # Verify all cell contents are present
            for num in ["1", "2", "3", "4", "5", "6", "A", "B", "C"]
                @test contains(output, num)
            end
        end

        @testset "Footnotes" begin
            output = render_to_typst(
                """
                Text with footnote[^1].

                [^1]: Footnote content here
                """
            )
            @test contains(output, "#footnote[")
            @test contains(output, "Footnote content here")
        end

        @testset "Links - External" begin
            output = render_to_typst("[Link text](https://example.com)")
            @test strip(output) == "#link(\"https://example.com\")[Link text]"
        end

        @testset "Special Characters" begin
            # Test escaping in text content
            # Build test string using Chars to avoid $ triggering Documenter warnings
            special_chars = join(['@', '#', '*', '_', '\\', '$', '/', '`', '<', '>'])
            input_md = "Special: " * special_chars
            output = render_to_typst(input_md)
            # Note: $ gets escaped as \$, / gets escaped as \/, backslash itself needs escaping
            @test contains(output, "Special:")
            @test contains(output, "\\@")
            @test contains(output, "\\#")
            @test contains(output, "\\*")
            @test contains(output, "\\_")
            @test contains(output, "\\/")
            @test contains(output, "\\`")
            @test contains(output, "\\<")
            @test contains(output, "\\>")
        end
    end

    # ============================================================================
    # Integration Tests - Full Document Builds
    # ============================================================================

    @testset "Integration: Basic Build" begin
        mktempdir() do dir
            srcdir = joinpath(dir, "src")
            mkpath(srcdir)

            write(
                joinpath(srcdir, "index.md"),
                """
                # Test Document

                Text **bold** and *italic* and `code`.

                ```julia
                x = 1 + 1
                ```
                """
            )

            makedocs(
                root = dir,
                source = "src",
                build = "build",
                sitename = "BasicTest",
                format = DocumenterTypst.Typst(platform = "none"),
                pages = ["index.md"],
                doctest = false,
                remotes = nothing
            )

            typfile = joinpath(dir, "build", "BasicTest.typ")
            @test isfile(typfile)
            content = read(typfile, String)

            # Verify header - exact matching
            @test contains(content, "#import(\"documenter.typ\")")
            @test contains(content, "title: [BasicTest]")

            # Verify content components exist
            @test contains(content, "Test Document")
            @test contains(content, "#strong([")
            @test contains(content, "#emph([")
            @test contains(content, "#raw(")

            # Verify documenter.typ was copied
            @test isfile(joinpath(dir, "build", "documenter.typ"))
        end
    end

    @testset "Integration: Math Rendering" begin
        mktempdir() do dir
            srcdir = joinpath(dir, "src")
            mkpath(srcdir)

            write(
                joinpath(srcdir, "index.md"),
                """
                # Math Test

                Display LaTeX: 

                ```math
                \\sum_{i=1}^n i
                ```

                Inline: ``\\alpha``

                Native Typst: 

                ```math typst
                sum_(i=1)^n i
                ```
                """
            )

            makedocs(
                root = dir,
                source = "src",
                build = "build",
                sitename = "MathTest",
                format = DocumenterTypst.Typst(platform = "none"),
                pages = ["index.md"],
                doctest = false,
                remotes = nothing
            )

            typfile = joinpath(dir, "build", "MathTest.typ")
            @test isfile(typfile)
            content = read(typfile, String)

            # Verify LaTeX math uses mitex - exact function call
            @test contains(content, "#mitex(\"")
            @test contains(content, "\\\\sum_{i=1}^n i")

            # Verify inline math uses mi
            @test contains(content, "#mi(\"")
            @test contains(content, "\\\\alpha")

            # Verify Typst math block contains the formula
            @test contains(content, "sum_(i=1)^n i")
        end
    end

    @testset "Integration: Rich Content" begin
        mktempdir() do dir
            srcdir = joinpath(dir, "src")
            mkpath(srcdir)

            write(
                joinpath(srcdir, "index.md"),
                """
                # Test Document

                ## Lists

                - Item 1
                - Item 2

                1. First
                2. Second

                ## Quote

                > This is a quote

                ---

                !!! note "Note Title"
                    Note content here

                ## Table

                | A | B |
                |---|---|
                | 1 | 2 |
                """
            )

            makedocs(
                root = dir,
                source = "src",
                build = "build",
                sitename = "RichTest",
                format = DocumenterTypst.Typst(platform = "none"),
                pages = ["index.md"],
                doctest = false,
                remotes = nothing
            )

            typfile = joinpath(dir, "build", "RichTest.typ")
            @test isfile(typfile)
            content = read(typfile, String)

            # Verify various elements are present with exact structures
            @test contains(content, "-")  # List items (unordered)
            @test contains(content, "+")  # Ordered list items
            @test contains(content, "#safe-block(inset: 10pt)[")  # BlockQuote
            @test contains(content, "#line(length: 100%)")   # ThematicBreak
            @test contains(content, "#admonition(type: \"note\"")  # Admonition
            @test contains(content, "#table(")    # Table
        end
    end

    @testset "Integration: Version Handling" begin
        mktempdir() do dir
            srcdir = joinpath(dir, "src")
            mkpath(srcdir)
            write(joinpath(srcdir, "index.md"), "# Test\n")

            # Test with semantic version
            makedocs(
                root = dir,
                source = "src",
                build = "build",
                sitename = "Version Test",
                format = DocumenterTypst.Typst(platform = "none", version = "1.2.3"),
                pages = ["index.md"],
                doctest = false,
                remotes = nothing
            )

            # File should be named with version
            @test isfile(joinpath(dir, "build", "VersionTest-1.2.3.typ"))
        end
    end

    @testset "Integration: Custom Template" begin
        mktempdir() do dir
            srcdir = joinpath(dir, "src")
            mkpath(srcdir)
            assetsdir = joinpath(srcdir, "assets")
            mkpath(assetsdir)

            write(joinpath(srcdir, "index.md"), "# Test\n")
            write(joinpath(assetsdir, "custom.typ"), "// Custom Typst config\n")

            makedocs(
                root = dir,
                source = "src",
                build = "build",
                sitename = "CustomTest",
                format = DocumenterTypst.Typst(platform = "none"),
                pages = ["index.md"],
                doctest = false,
                remotes = nothing
            )

            # custom.typ content should be embedded in the generated .typ file
            typfile = joinpath(dir, "build", "CustomTest.typ")
            @test isfile(typfile)
            typ_content = read(typfile, String)
            @test contains(typ_content, "Custom Typst config")
        end
    end

    @testset "Integration: Images" begin
        mktempdir() do dir
            srcdir = joinpath(dir, "src")
            mkpath(srcdir)
            assetsdir = joinpath(srcdir, "assets")
            mkpath(assetsdir)

            # Create dummy image
            write(joinpath(assetsdir, "image.png"), "fake png")

            write(joinpath(srcdir, "index.md"), "![Caption](assets/image.png)")

            makedocs(
                root = dir,
                source = "src",
                build = "build",
                sitename = "ImgTest",
                format = DocumenterTypst.Typst(platform = "none"),
                pages = ["index.md"],
                doctest = false,
                remotes = nothing
            )

            content = read(joinpath(dir, "build", "ImgTest.typ"), String)
            # Verify exact image rendering structure
            @test contains(content, "#figure(")
            @test contains(content, "image(")
            @test contains(content, "Caption")
        end
    end

    @testset "Integration: Multi-page" begin
        mktempdir() do dir
            srcdir = joinpath(dir, "src")
            mkpath(srcdir)
            write(joinpath(srcdir, "index.md"), "# Home\n")
            write(joinpath(srcdir, "page2.md"), "# Page 2\n")

            makedocs(
                root = dir,
                source = "src",
                build = "build",
                sitename = "Multi",
                format = DocumenterTypst.Typst(platform = "none"),
                pages = ["index.md", "page2.md"],
                doctest = false,
                remotes = nothing
            )

            content = read(joinpath(dir, "build", "Multi.typ"), String)
            # Both pages should be in the single output file
            @test contains(content, "Home")
            @test contains(content, "Page 2")
        end
    end

    @testset "Integration: Code Languages" begin
        output = render_to_typst(
            """
            ```python
            def hello():
                pass
            ```

            ```@repl
            x = 1
            ```

            ```text/plain
            plain
            ```
            """
        )
        # Verify exact language mappings
        @test contains(output, "lang: \"python\"")
        @test contains(output, "lang: \"julia\"")  # @repl → julia
        @test contains(output, "lang: \"text\"")   # text/plain → text
    end

    @testset "Integration: Nested Structures" begin
        output = render_to_typst(
            """
            > Quote with **bold**

            - List with `code`

            !!! note "Note"
                With *italic*
            """
        )
        # Verify all nested formatting constructs are present
        @test contains(output, "#safe-block")  # BlockQuote now uses safe-block
        @test contains(output, "#strong")
        @test contains(output, "#raw")
        @test contains(output, "#emph")
        @test contains(output, "#admonition")
    end

    @testset "Configuration: PDF Optimization" begin
        # Test that optimize_pdf option is accepted and stored correctly
        format_with_opt = DocumenterTypst.Typst(; optimize_pdf = true)
        @test format_with_opt.optimize_pdf

        format_without_opt = DocumenterTypst.Typst(; optimize_pdf = false)
        @test !format_without_opt.optimize_pdf

        # Test default is true
        format_default = DocumenterTypst.Typst()
        @test format_default.optimize_pdf
    end

    @testset "Configuration: System Fonts" begin
        # Test that use_system_fonts option is accepted and stored correctly
        format_with_sys_fonts = DocumenterTypst.Typst(; use_system_fonts = true)
        @test format_with_sys_fonts.use_system_fonts

        format_without_sys_fonts = DocumenterTypst.Typst(; use_system_fonts = false)
        @test !format_without_sys_fonts.use_system_fonts

        # Test default is true
        format_default = DocumenterTypst.Typst()
        @test format_default.use_system_fonts
    end

    @testset "Configuration: Font Paths" begin
        # Test empty font paths (default)
        format_default = DocumenterTypst.Typst()
        @test isempty(format_default.font_paths)

        # Test with custom font paths
        custom_paths = ["/usr/share/fonts", "/opt/fonts"]
        format_with_paths = DocumenterTypst.Typst(; font_paths = custom_paths)
        @test format_with_paths.font_paths == custom_paths
        @test length(format_with_paths.font_paths) == 2
    end
end

end # module
