#!/usr/bin/env julia
# Unit Tests for DocumenterTypst
# Fast tests without compilation - should run on all platforms and Julia versions

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

include("test_helpers.jl")

# ============================================================================
# Helper: Suppress expected warnings/errors in tests
# ============================================================================

"""
    suppress_expected_logs(f; level=Logging.Error)

Run function `f` with log level set to `level` (default: Error).
This suppresses Info and Warning logs, useful for tests that intentionally
trigger expected warnings (e.g., missing docstrings with warnonly=true).
"""
function suppress_expected_logs(f; level = Logging.Error)
    return with_logger(ConsoleLogger(stderr, level)) do
        f()
    end
end

# ============================================================================
# UNIT TESTS (PART 1 + PART 2 from original runtests.jl)
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
                "#heading(level: 1, [Level 1])\n\n #label(\"index.md#Level-1\")"

            output = render_to_typst("## Level 2")
            @test strip(output) ==
                "#heading(level: 2, [Level 2])\n\n #label(\"index.md#Level-2\")"

            output = render_to_typst("### Level 3")
            @test strip(output) ==
                "#heading(level: 3, [Level 3])\n\n #label(\"index.md#Level-3\")"
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

            # Nested lists - verify structure preserved
            output = render_to_typst("- Level 1\n  - Level 2\n    - Level 3")
            @test contains(output, "- Level 1")
            @test contains(output, "  - Level 2")
            @test contains(output, "    - Level 3")
        end

        @testset "Tables" begin
            output = render_to_typst("| A | B |\n|---|---|\n| 1 | 2 |")
            # Should generate #table(...) with proper structure
            @test contains(output, "#table(")
            @test contains(output, "columns:")
            @test contains(output, "[A]")
            @test contains(output, "[B]")
            @test contains(output, "[1]")
            @test contains(output, "[2]")
        end

        @testset "Links" begin
            # External link
            output = render_to_typst("[Link text](https://example.com)")
            @test strip(output) == "#link(\"https://example.com\")[Link text]"

            # Internal reference - absolute path
            output = render_to_typst("[Link text](#section)")
            @test contains(output, "#link")
            @test contains(output, "label")
        end

        @testset "Images" begin
            # Create temp file to avoid Documenter file existence check
            mktempdir() do dir
                src_dir = joinpath(dir, "src")
                mkpath(src_dir)
                write(joinpath(src_dir, "index.md"), "![Alt text](image.png)")
                touch(joinpath(src_dir, "image.png"))  # Create empty image file (same dir as index.md)

                makedocs(;
                    root = dir,
                    source = "src",
                    build = "build",
                    format = DocumenterTypst.Typst(platform = "none"),
                    sitename = "Test",
                    pages = ["index.md"],
                    warnonly = true,
                    remotes = nothing,
                )

                output = read(joinpath(dir, "build", "Test.typ"), String)
                @test contains(output, "#figure")
                @test contains(output, "image(")
                @test contains(output, "image.png")
                @test contains(output, "Alt text")
            end
        end

        @testset "Block Quotes" begin
            output = render_to_typst("> This is a quote\n> Second line")
            @test contains(output, "#quote")
            @test contains(output, "This is a quote")
            @test contains(output, "Second line")
        end

        @testset "Horizontal Rules" begin
            output = render_to_typst("---")
            @test contains(output, "#line")
        end

        @testset "Footnotes" begin
            output = render_to_typst("Text with footnote[^1].\n\n[^1]: Footnote content.")
            @test contains(output, "#footnote")
            @test contains(output, "Footnote content")
        end
    end

    # ============================================================================
    # PART 2: Extended Coverage
    # ============================================================================

    @testset "Extended Coverage" begin
        @testset "Documenter Specific Nodes" begin
            @testset "DocsNode" begin
                mktempdir() do dir
                    srcdir = joinpath(dir, "src")
                    mkpath(srcdir)

                    write(
                        joinpath(srcdir, "index.md"), """
                        # Module Reference

                        ```@docs
                        Base.abs
                        ```
                        """
                    )

                    # Suppress expected warnings (missing docstrings for Base functions)
                    suppress_expected_logs() do
                        makedocs(;
                            root = dir,
                            source = "src",
                            build = "build",
                            sitename = "DocsTest",
                            format = DocumenterTypst.Typst(; platform = "none"),
                            pages = ["index.md"],
                            doctest = false,
                            remotes = nothing,
                            warnonly = true,  # Allow missing docstrings
                        )
                    end

                    typfile = joinpath(dir, "build", "DocsTest.typ")
                    @test isfile(typfile)

                    content = read(typfile, String)
                    @test contains(content, "abs")
                end
            end

            @testset "IndexNode" begin
                mktempdir() do dir
                    srcdir = joinpath(dir, "src")
                    mkpath(srcdir)

                    write(
                        joinpath(srcdir, "index.md"), """
                        # Index Test

                        ```@index
                        ```
                        """
                    )

                    makedocs(;
                        root = dir,
                        source = "src",
                        build = "build",
                        sitename = "IndexTest",
                        format = DocumenterTypst.Typst(; platform = "none"),
                        pages = ["index.md"],
                        doctest = false,
                        remotes = nothing,
                    )

                    typfile = joinpath(dir, "build", "IndexTest.typ")
                    @test isfile(typfile)
                end
            end

            @testset "ContentsNode" begin
                mktempdir() do dir
                    srcdir = joinpath(dir, "src")
                    mkpath(srcdir)

                    write(
                        joinpath(srcdir, "index.md"), """
                        # Contents Test

                        ```@contents
                        ```
                        """
                    )

                    makedocs(;
                        root = dir,
                        source = "src",
                        build = "build",
                        sitename = "ContentsTest",
                        format = DocumenterTypst.Typst(; platform = "none"),
                        pages = ["index.md"],
                        doctest = false,
                        remotes = nothing,
                    )

                    typfile = joinpath(dir, "build", "ContentsTest.typ")
                    @test isfile(typfile)
                    content = read(typfile, String)
                    @test contains(content, "- #link(label(\"index.md#Contents-Test\"))[Contents Test]")
                end
            end

            @testset "RawNode" begin
                mktempdir() do dir
                    srcdir = joinpath(dir, "src")
                    mkpath(srcdir)

                    write(
                        joinpath(srcdir, "index.md"), """
                        # Raw Test

                        ```@raw typst
                        #text(fill: red)[Custom Typst code]
                        ```
                        """
                    )

                    makedocs(;
                        root = dir,
                        source = "src",
                        build = "build",
                        sitename = "RawTest",
                        format = DocumenterTypst.Typst(; platform = "none"),
                        pages = ["index.md"],
                        doctest = false,
                        remotes = nothing,
                    )

                    typfile = joinpath(dir, "build", "RawTest.typ")
                    @test isfile(typfile)
                    content = read(typfile, String)
                    @test contains(content, "#text(fill: red)[Custom Typst code]")
                end
            end
        end

        @testset "Unicode & International" begin
            @testset "Chinese Characters" begin
                output = render_to_typst("中文测试 **粗体** _斜体_")
                @test contains(output, "中文测试")
                @test contains(output, "#strong([粗体])")
                @test contains(output, "#emph([斜体])")
            end

            @testset "Russian Cyrillic" begin
                output = render_to_typst("Русский текст **жирный** _курсив_")
                @test contains(output, "Русский текст")
                @test contains(output, "#strong([жирный])")
                @test contains(output, "#emph([курсив])")
            end

            @testset "Arabic" begin
                output = render_to_typst("النص العربي **غامق** _مائل_")
                @test contains(output, "النص العربي")
                @test contains(output, "#strong([غامق])")
                @test contains(output, "#emph([مائل])")
            end

            @testset "Emoji" begin
                output = render_to_typst("Text with emoji: 🎉 ✅ ❌")
                @test contains(output, "🎉")
                @test contains(output, "✅")
                @test contains(output, "❌")
            end
        end

        @testset "Edge Cases" begin
            @testset "Deep Nesting" begin
                # 5 levels deep list
                deep_list = """
                - L1
                  - L2
                    - L3
                      - L4
                        - L5
                """
                output = render_to_typst(deep_list)
                @test contains(output, "L1")
                @test contains(output, "L5")
            end

            @testset "Long Lines" begin
                long_text = "A" * "B"^500 * "C"
                output = render_to_typst(long_text)
                @test contains(output, "A")
                @test contains(output, "B")
                @test contains(output, "C")
            end

            @testset "Large Table" begin
                # 20 columns × 10 rows
                header = "| " * join(["C$i" for i in 1:20], " | ") * " |"
                separator = "|" * join(["---" for i in 1:20], "|") * "|"
                rows = [
                    "| " * join(["R$(j)C$i" for i in 1:20], " | ") * " |" for
                        j in 1:10
                ]
                table = join([header, separator, rows...], "\n")

                output = render_to_typst(table)
                @test contains(output, "#table")
                @test contains(output, "C1")
                @test contains(output, "C20")
                @test contains(output, "R10C20")
            end

            @testset "Empty Elements" begin
                @test strip(render_to_typst("")) == ""
                # Empty bold renders as literal **
                @test contains(render_to_typst("**"), "\\*\\*")
                # Empty link renders empty
                @test contains(render_to_typst("[]()"), "#link")
            end
        end

        @testset "Error Detection" begin
            @testset "Missing Images" begin
                # Suppress expected error logs
                @test_throws ErrorException suppress_expected_logs() do
                    mktempdir() do dir
                        srcdir = joinpath(dir, "src")
                        mkpath(srcdir)

                        write(
                            joinpath(srcdir, "index.md"), """
                            ![Caption](nonexistent.png)
                            """
                        )

                        makedocs(;
                            root = dir,
                            source = "src",
                            build = "build",
                            sitename = "Test",
                            format = DocumenterTypst.Typst(; platform = "none"),
                            pages = ["index.md"],
                            doctest = false,
                            remotes = nothing,
                        )
                    end
                end
            end

            @testset "Undefined Footnote" begin
                # Suppress expected error logs
                @test_throws ErrorException suppress_expected_logs() do
                    mktempdir() do dir
                        srcdir = joinpath(dir, "src")
                        mkpath(srcdir)

                        write(
                            joinpath(srcdir, "index.md"), """
                            Text with undefined footnote[^undefined].
                            """
                        )

                        makedocs(;
                            root = dir,
                            source = "src",
                            build = "build",
                            sitename = "Test",
                            format = DocumenterTypst.Typst(; platform = "none"),
                            pages = ["index.md"],
                            doctest = false,
                            remotes = nothing,
                        )
                    end
                end
            end
        end

        @testset "Graceful Degradation" begin
            @testset "Missing Image with warnonly" begin
                mktempdir() do dir
                    srcdir = joinpath(dir, "src")
                    mkpath(srcdir)

                    write(
                        joinpath(srcdir, "index.md"), """
                        ![Caption](nonexistent.png)
                        """
                    )

                    # Suppress expected warnings (missing image with warnonly)
                    suppress_expected_logs() do
                        makedocs(;
                            root = dir,
                            source = "src",
                            build = "build",
                            sitename = "Test",
                            format = DocumenterTypst.Typst(; platform = "none"),
                            pages = ["index.md"],
                            doctest = false,
                            remotes = nothing,
                            warnonly = true,
                        )
                    end

                    typfile = joinpath(dir, "build", "Test.typ")
                    @test isfile(typfile)
                end
            end

            @testset "Undefined Footnote with warnonly" begin
                mktempdir() do dir
                    srcdir = joinpath(dir, "src")
                    mkpath(srcdir)

                    write(
                        joinpath(srcdir, "index.md"), """
                        Text with undefined footnote[^undef].
                        """
                    )

                    # Suppress expected warnings (undefined footnote with warnonly)
                    suppress_expected_logs() do
                        makedocs(;
                            root = dir,
                            source = "src",
                            build = "build",
                            sitename = "Test",
                            format = DocumenterTypst.Typst(; platform = "none"),
                            pages = ["index.md"],
                            doctest = false,
                            remotes = nothing,
                            warnonly = true,
                        )
                    end

                    typfile = joinpath(dir, "build", "Test.typ")
                    @test isfile(typfile)
                    content = read(typfile, String)
                    @test contains(content, "undef")
                end
            end
        end

        @testset "Real-World Scenarios" begin
            @testset "Full API Documentation" begin
                mktempdir() do dir
                    srcdir = joinpath(dir, "src")
                    mkpath(srcdir)

                    write(
                        joinpath(srcdir, "api.md"), """
                        # API Reference

                        ## Mathematical Functions

                        ```@docs
                        Base.abs
                        Base.abs2
                        Base.sign
                        Base.sqrt
                        ```

                        ## Trigonometric Functions

                        ```@docs
                        Base.sin
                        Base.cos
                        Base.tan
                        ```
                        """
                    )

                    # Suppress expected warnings (missing docstrings for Base functions)
                    suppress_expected_logs() do
                        makedocs(;
                            root = dir,
                            source = "src",
                            build = "build",
                            sitename = "Test",
                            format = DocumenterTypst.Typst(; platform = "none"),
                            pages = ["api.md"],
                            doctest = false,
                            remotes = nothing,
                            warnonly = true,  # Allow missing docstrings
                        )
                    end

                    typfile = joinpath(dir, "build", "Test.typ")
                    @test isfile(typfile)

                    content = read(typfile, String)
                    @test contains(content, "abs")
                    @test contains(content, "sin")
                end
            end

            @testset "Mixed Content" begin
                mktempdir() do dir
                    srcdir = joinpath(dir, "src")
                    mkpath(srcdir)

                    write(
                        joinpath(srcdir, "index.md"), """
                        # Complex Document

                        ## Introduction

                        This document contains **various** *elements*.

                        ### Lists

                        - Item 1
                        - Item 2
                          - Nested item

                        ### Code

                        ```julia
                        function test()
                            return 42
                        end
                        ```

                        ### Math

                        Inline ``\\alpha`` and display:

                        ```math
                        \\sum_{i=1}^n i = \\frac{n(n+1)}{2}
                        ```

                        ### Table

                        | A | B | C |
                        |---|---|---|
                        | 1 | 2 | 3 |

                        ### Admonition

                        !!! note
                            Important information here.
                        """
                    )

                    makedocs(;
                        root = dir,
                        source = "src",
                        build = "build",
                        sitename = "Test",
                        format = DocumenterTypst.Typst(; platform = "none"),
                        pages = ["index.md"],
                        doctest = false,
                        remotes = nothing,
                    )

                    typfile = joinpath(dir, "build", "Test.typ")
                    @test isfile(typfile)

                    content = read(typfile, String)
                    # Verify all elements present
                    @test contains(content, "#strong")  # bold
                    @test contains(content, "#emph")  # italic
                    @test contains(content, "- ")  # list
                    @test contains(content, "#table(")  # table
                    @test contains(content, "#admonition")  # admonition
                    @test contains(content, "#mi(")  # inline math
                    @test contains(content, "#mitex(")  # display math
                end
            end
        end
    end
end

end # module
