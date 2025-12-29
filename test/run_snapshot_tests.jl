#!/usr/bin/env julia
# Standalone runner for snapshot tests (text + visual)
# Should only run on a single platform (ubuntu + julia 1)

using Test
using Documenter
using DocumenterTypst
using Logging

Logging.disable_logging(Logging.Info)
using DocumenterTypst.TypstWriter:
    TypstWriter, escape_for_typst_string, typstesc,
    typstescstr, writer_supports_ansicolor

include("test_helpers.jl")
include("snapshot_helpers.jl")
include("visual_helpers.jl")

@testset "Snapshot Tests" begin
    update = should_update_snapshots()

    # Control which tests to run via environment variables
    skip_text = get(ENV, "SKIP_TEXT_SNAPSHOTS", "0") == "1"
    skip_visual = get(ENV, "SKIP_VISUAL_SNAPSHOTS", "0") == "1"

    if !skip_text
        @testset "Text Snapshots" begin
            @testset "Basic Markdown Nodes" begin
                test_snapshot("heading_h1", "# Heading 1"; update)
                test_snapshot("heading_h2", "## Heading 2"; update)
                test_snapshot("heading_h3", "### Heading 3"; update)

                test_snapshot("paragraph_simple", "Simple paragraph text."; update)
                test_snapshot(
                    "paragraph_multiple", """
                    First paragraph.

                    Second paragraph.
                    """; update
                )

                test_snapshot("strong", "**bold text**"; update)
                test_snapshot("emph", "_italic text_"; update)
                test_snapshot("strong_emph", "**bold** and _italic_"; update)

                test_snapshot("code_inline", "`code` inline"; update)
                test_snapshot("link", "[link text](https://example.com)"; update)
            end

            @testset "Lists" begin
                test_snapshot(
                    "list_unordered", """
                    - Item 1
                    - Item 2
                    - Item 3
                    """; update
                )

                test_snapshot(
                    "list_ordered", """
                    1. First
                    2. Second
                    3. Third
                    """; update
                )

                test_snapshot(
                    "list_nested", """
                    - Top level
                      - Nested item
                      - Another nested
                    - Back to top
                    """; update
                )
            end

            @testset "Code Blocks" begin
                test_snapshot(
                    "code_block_julia", """
                    ```julia
                    x = 1
                    y = 2
                    ```
                    """; update
                )

                test_snapshot(
                    "code_block_python", """
                    ```python
                    def foo():
                        return 42
                    ```
                    """; update
                )
            end

            @testset "Tables" begin
                test_snapshot(
                    "table_simple", """
                    | A | B |
                    |---|---|
                    | 1 | 2 |
                    """; update
                )

                test_snapshot(
                    "table_alignment", """
                    | Left | Center | Right |
                    |:-----|:------:|------:|
                    | L    | C      | R     |
                    """; update
                )
            end

            @testset "Block Elements" begin
                test_snapshot(
                    "blockquote", """
                    > This is a quote.
                    > Second line.
                    """; update
                )

                test_snapshot(
                    "horizontal_rule", """
                    Before

                    ---

                    After
                    """; update
                )
            end

            @testset "Math" begin
                test_snapshot("math_inline", raw"Inline math: $\alpha + \beta$"; update)
                test_snapshot(
                    "math_display", raw"""
                    Display math:

                    $$
                    E = mc^2
                    $$
                    """; update
                )
            end

            @testset "Admonitions" begin
                test_snapshot(
                    "admonition_note", """
                    !!! note
                        This is a note.
                    """; update
                )

                test_snapshot(
                    "admonition_warning", """
                    !!! warning "Custom Title"
                        Be careful!
                    """; update
                )
            end

            @testset "Complex Structures" begin
                test_snapshot(
                    "mixed_content", """
                    # Main Title

                    This is a paragraph with **bold** and _italic_.

                    ## Subsection

                    - List item 1
                    - List item 2

                    ```julia
                    code_example()
                    ```

                    | Col1 | Col2 |
                    |------|------|
                    | A    | B    |
                    """; update
                )

                test_snapshot(
                    "footnote", """
                    Text with footnote[^1].

                    [^1]: Footnote content.
                    """; update
                )
            end
        end
    else
        @test_skip "Text snapshots skipped (SKIP_TEXT_SNAPSHOTS=1)"
    end

    if !skip_visual
        @testset "Visual Snapshots" begin
            # Set platform to none to keep .typ files
            ENV["TYPST_PLATFORM"] = "none"

            clean_visual_failures()

            fixtures_dir = joinpath(@__DIR__, "integration", "fixtures")

            @testset "Enhanced Typst Fixture" begin
                fixture_dir = joinpath(@__DIR__, "integration", "fixtures", "enhanced_typst")

                try
                    # Build fixture (using test/integration project environment)
                    integration_project = joinpath(@__DIR__, "integration")
                    run(
                        pipeline(
                            `julia --project=$integration_project $(joinpath(fixture_dir, "make.jl"))`,
                            stderr = devnull,
                            stdout = devnull
                        )
                    )

                    # Find generated .typ file
                    build_dir = joinpath(fixture_dir, "build")
                    typ_files = filter(f -> endswith(f, ".typ"), readdir(build_dir))
                    main_typs = filter(f -> !endswith(f, "documenter.typ") && !startswith(f, "enhanced"), typ_files)

                    if !isempty(main_typs)
                        typ_path = joinpath(build_dir, first(main_typs))
                        test_visual_from_file("enhanced_typst", typ_path; update)
                    else
                        @error "No main .typ file found in fixture" build_dir = build_dir
                        @test false
                    end
                catch e
                    @error "Enhanced Typst fixture failed" exception = e
                    @test false
                end
            end

            @testset "Pure Typst Fixture" begin
                fixture_dir = joinpath(fixtures_dir, "pure_typst")

                try
                    # Build fixture (using test/integration project environment)
                    integration_project = joinpath(@__DIR__, "integration")
                    run(
                        pipeline(
                            `julia --project=$integration_project $(joinpath(fixture_dir, "make.jl"))`,
                            stderr = devnull,
                            stdout = devnull
                        )
                    )

                    # Find generated .typ file
                    build_dir = joinpath(fixture_dir, "build")
                    typ_files = filter(f -> endswith(f, ".typ"), readdir(build_dir))
                    main_typs = filter(
                        f -> !endswith(f, "documenter.typ") && !startswith(basename(f), "simple"),
                        typ_files
                    )

                    if !isempty(main_typs)
                        typ_path = joinpath(build_dir, first(main_typs))
                        test_visual_from_file("pure_typst", typ_path; update)
                    else
                        @error "No main .typ file found in fixture" build_dir = build_dir
                        @test false
                    end
                catch e
                    @error "Pure Typst fixture failed" exception = e
                    @test false
                end
            end

            @testset "Link Edge Cases Fixture" begin
                fixture_dir = joinpath(fixtures_dir, "link_edge_cases")

                try
                    # Build fixture (using test/integration project environment)
                    integration_project = joinpath(@__DIR__, "integration")
                    run(
                        pipeline(
                            `julia --project=$integration_project $(joinpath(fixture_dir, "make.jl"))`,
                            stderr = devnull,
                            stdout = devnull
                        )
                    )

                    # Find generated .typ file
                    build_dir = joinpath(fixture_dir, "build")
                    typ_files = filter(f -> endswith(f, ".typ"), readdir(build_dir))
                    main_typs = filter(f -> !endswith(f, "documenter.typ"), typ_files)

                    if !isempty(main_typs)
                        typ_path = joinpath(build_dir, first(main_typs))
                        test_visual_from_file("link_edge_cases", typ_path; update)
                    else
                        @error "No main .typ file found in fixture" build_dir = build_dir
                        @test false
                    end
                catch e
                    @error "Link Edge Cases fixture failed" exception = e
                    @test false
                end
            end

            @testset "Template Configuration Tests" begin
                @testset "No Header Mode" begin
                    test_visual(
                        "config_no_header", """
                        #import "documenter.typ": *

                        #show: documenter.with(
                          title: "No Header Test",
                          date: "2025-01-01",
                          config: (header-mode: "none")
                        )

                        = Part 1
                        == Chapter 1
                        Content on first page.

                        #pagebreak()

                        Second page - should have no header.

                        #pagebreak()

                        Third page - still no header.
                        """; update
                    )
                end

                @testset "Custom Footer Alignment" begin
                    test_visual(
                        "config_footer_left", """
                        #import "documenter.typ": *

                        #show: documenter.with(
                          title: "Footer Alignment",
                          date: "2025-01-01",
                          config: (footer-alignment: left)
                        )

                        = Part 1
                        == Chapter 1
                        Testing left-aligned footer.
                        """; update
                    )
                end

                @testset "Builtin Code Engine" begin
                    test_visual(
                        "config_builtin_code", """
                        #import "documenter.typ": *

                        #show: documenter.with(
                          title: "Builtin Code",
                          date: "2025-01-01",
                          config: (codeblock-engine: "builtin")
                        )

                        = Part 1
                        == Code Examples

                        ```julia
                        function example()
                            x = 1
                            y = 2
                            return x + y
                        end
                        ```

                        More content here.
                        """; update
                    )
                end
            end
        end
    else
        @test_skip "Visual snapshots skipped (SKIP_VISUAL_SNAPSHOTS=1)"
    end
end
