# Typst Backend Integration Tests

using Test
using Documenter
using DocumenterTypst

# Get platform from environment variable
const PLATFORM = get(ENV, "TYPST_PLATFORM", "typst")

@info "Testing Typst backend with platform: $PLATFORM"

@testset "Typst Backend: $PLATFORM" begin
    @testset "Basic Document" begin
        mktempdir() do dir
            # Create source directory
            srcdir = joinpath(dir, "src")
            mkpath(srcdir)

            # Write a simple document
            write(
                joinpath(srcdir, "index.md"), """
                # Test Document

                This is a test document for platform: **$PLATFORM**.

                ## Features

                - Lists work
                - **Bold** and *italic*
                - `inline code`

                ### Code Block

                ```julia
                x = 1 + 1
                println("Result: ", x)
                ```
                """
            )

            # Build with Typst
            makedocs(
                root = dir,
                source = "src",
                build = "build",
                sitename = "BackendTest",
                format = DocumenterTypst.Typst(platform = PLATFORM),
                pages = ["index.md"],
                doctest = false,
                remotes = nothing,
            )

            # Verify output
            builddir = joinpath(dir, "build")
            @test isdir(builddir)

            # When platform != "none", .typ file is deleted after compilation
            # Only check .typ file for platform="none"
            if PLATFORM == "none"
                typfile = joinpath(builddir, "BackendTest.typ")
                @test isfile(typfile)

                # Verify .typ content
                content = read(typfile, String)
                @test contains(content, "Test Document")
                @test contains(content, "platform: ")
                @test contains(content, "Lists work")
            end

            # Check PDF was generated (except for platform="none")
            if PLATFORM != "none"
                pdffile = joinpath(builddir, "BackendTest.pdf")
                @test isfile(pdffile)
                @test filesize(pdffile) > 1000  # PDF should be non-trivial
            end
        end
    end

    @testset "Math Rendering" begin
        mktempdir() do dir
            srcdir = joinpath(dir, "src")
            mkpath(srcdir)

            write(
                joinpath(srcdir, "index.md"), """
                # Math Test

                ## LaTeX Math

                Inline: ``\\alpha + \\beta = \\gamma``

                Display:
                ```math
                \\sum_{i=1}^n i = \\frac{n(n+1)}{2}
                ```

                ## Native Typst Math

                ```math typst
                integral_0^oo e^(-x^2) dif x = sqrt(pi)/2
                ```
                """
            )

            makedocs(
                root = dir,
                source = "src",
                build = "build",
                sitename = "MathTest",
                format = DocumenterTypst.Typst(platform = PLATFORM),
                pages = ["index.md"],
                doctest = false,
                remotes = nothing,
            )

            # Only check .typ file for platform="none"
            if PLATFORM == "none"
                typfile = joinpath(dir, "build", "MathTest.typ")
                @test isfile(typfile)

                content = read(typfile, String)
                # LaTeX math should use mitex
                @test contains(content, "#mi(")
                # Native Typst math should be preserved
                @test contains(content, "integral")
            else
                # For other platforms, just verify PDF was created
                pdffile = joinpath(dir, "build", "MathTest.pdf")
                @test isfile(pdffile)
                @test filesize(pdffile) > 1000
            end
        end
    end

    @testset "Multi-page Document" begin
        mktempdir() do dir
            srcdir = joinpath(dir, "src")
            mkpath(srcdir)

            write(
                joinpath(srcdir, "index.md"), """
                # Home

                Welcome to the multi-page test.

                See also [Chapter 1](chapter1.md).
                """
            )

            write(
                joinpath(srcdir, "chapter1.md"), """
                # Chapter 1

                This is chapter 1.

                [Back to Home](index.md)
                """
            )

            makedocs(
                root = dir,
                source = "src",
                build = "build",
                sitename = "MultiPage",
                format = DocumenterTypst.Typst(platform = PLATFORM),
                pages = [
                    "Home" => "index.md",
                    "Chapter 1" => "chapter1.md",
                ],
                doctest = false,
                remotes = nothing,
            )

            # Only check .typ file for platform="none"
            if PLATFORM == "none"
                typfile = joinpath(dir, "build", "MultiPage.typ")
                @test isfile(typfile)

                content = read(typfile, String)
                @test contains(content, "Welcome to the multi-page test")
                @test contains(content, "This is chapter 1")
            end

            if PLATFORM != "none"
                pdffile = joinpath(dir, "build", "MultiPage.pdf")
                @test isfile(pdffile)
            end
        end
    end

    @testset "Tables and Images" begin
        mktempdir() do dir
            srcdir = joinpath(dir, "src")
            mkpath(srcdir)

            write(
                joinpath(srcdir, "index.md"), """
                # Tables and Images

                ## Table

                | Header 1 | Header 2 |
                |----------|----------|
                | Cell 1   | Cell 2   |
                | Cell 3   | Cell 4   |

                ## Special Characters

                Testing escaping: @#*_\\/`<>
                """
            )

            makedocs(
                root = dir,
                source = "src",
                build = "build",
                sitename = "TableTest",
                format = DocumenterTypst.Typst(platform = PLATFORM),
                pages = ["index.md"],
                doctest = false,
                remotes = nothing,
            )

            # Only check .typ file for platform="none"
            if PLATFORM == "none"
                typfile = joinpath(dir, "build", "TableTest.typ")
                @test isfile(typfile)

                content = read(typfile, String)
                @test contains(content, "#table(")
                @test contains(content, "Header 1")
                # Check escaping
                @test contains(content, "\\@")
            else
                # For other platforms, just verify PDF was created
                pdffile = joinpath(dir, "build", "TableTest.pdf")
                @test isfile(pdffile)
                @test filesize(pdffile) > 1000
            end
        end
    end

    @testset "Pure Typst Files" begin
        fixture_dir = joinpath(@__DIR__, "fixtures", "pure_typst")

        if isdir(fixture_dir)
            mktempdir() do tmpdir
                # Copy fixture to temporary directory
                cp(fixture_dir, joinpath(tmpdir, "pure_typst"))
                test_dir = joinpath(tmpdir, "pure_typst")

                # Run makedocs
                cd(test_dir) do
                    include(joinpath(test_dir, "make.jl"))
                end

                builddir = joinpath(test_dir, "build")
                @test isdir(builddir)

                # Check for platform="none"
                if PLATFORM == "none"
                    typfile = joinpath(builddir, "PureTypstTest-0.1.0.typ")
                    @test isfile(typfile)

                    content = read(typfile, String)

                    # Verify mixed .md and .typ content
                    @test contains(content, "Pure Typst Test Documentation")  # from index.md

                    # Extract all extended_include calls and their offsets
                    includes = Dict{String, Vector{Int}}()
                    for m in eachmatch(r"#extended_include\(\"([^\"]+)\.typ\", offset: (\d+)\)", content)
                        filepath = m.captures[1]
                        offset = parse(Int, m.captures[2])
                        if !haskey(includes, filepath)
                            includes[filepath] = Int[]
                        end
                        push!(includes[filepath], offset)
                    end

                    # Test depth=1, no title => offset=0 (first occurrence of simple.typ)
                    @test haskey(includes, "simple")
                    @test 0 in includes["simple"]

                    # Test depth=1, with title => offset=1 (second occurrence of simple.typ)
                    @test 1 in includes["simple"]

                    # Test depth=2, with title => offset=2
                    @test haskey(includes, "nested/with_image")
                    @test includes["nested/with_image"] == [2]

                    # Test depth=3, with title => offset=3
                    @test haskey(includes, "nested/level3")
                    @test includes["nested/level3"] == [3]

                    # Verify .typ files exist in build directory
                    @test isfile(joinpath(builddir, "simple.typ"))
                    @test isfile(joinpath(builddir, "nested", "with_image.typ"))
                    @test isfile(joinpath(builddir, "nested", "level3.typ"))

                    @test contains(content, "#heading(")
                else
                    # For other platforms, verify PDF was created
                    pdffile = joinpath(builddir, "PureTypstTest-0.1.0.pdf")
                    @test isfile(pdffile)
                    @test filesize(pdffile) > 1000
                end
            end
        else
            @warn "Pure Typst fixture not found at $fixture_dir, skipping test"
        end
    end

    @testset "Enhanced Typst with Documenter Directives" begin
        fixture_dir = joinpath(@__DIR__, "fixtures", "enhanced_typst")

        if isdir(fixture_dir)
            mktempdir() do tmpdir
                # Copy fixture to temporary directory
                cp(fixture_dir, joinpath(tmpdir, "enhanced_typst"))
                test_dir = joinpath(tmpdir, "enhanced_typst")

                # Run makedocs
                cd(test_dir) do
                    include(joinpath(test_dir, "make.jl"))
                end

                builddir = joinpath(test_dir, "build")
                @test isdir(builddir)

                # Check for platform="none"
                if PLATFORM == "none"
                    typfile = joinpath(builddir, "EnhancedTypstTest-0.1.0.typ")
                    @test isfile(typfile)

                    main_content = read(typfile, String)

                    # Verify enhanced.typ is included
                    @test contains(main_content, "#extended_include(\"enhanced.typ\"")

                    # Read the processed enhanced.typ
                    enhanced_file = joinpath(builddir, "enhanced.typ")
                    @test isfile(enhanced_file)

                    enhanced_content = read(enhanced_file, String)

                    # Test @typst-docs directive processing
                    @test contains(enhanced_content, "#raw(\"EnhancedTypstTest.greet\"")
                    @test contains(enhanced_content, "#raw(\"EnhancedTypstTest.add_numbers\"")
                    @test contains(enhanced_content, "Greet a person by name")
                    @test contains(enhanced_content, "Add two numbers together")
                    # Verify docstring code blocks are rendered correctly
                    @test contains(enhanced_content, "#raw(\"greet(name::String) -> String\"")

                    # Test @typst-example directive processing
                    @test contains(enhanced_content, "EnhancedTypstTest.add_numbers(5, 7)")
                    @test contains(enhanced_content, "Result: 12")
                    # Verify proper Typst escaping (double quotes, not single quotes)
                    @test contains(enhanced_content, "#raw(\"Result: 12\"")
                    @test !contains(enhanced_content, "#raw('Result: 12'")

                    # Test @typst-ref directive processing
                    @test contains(enhanced_content, "#link(label(\"enhanced.typ#EnhancedTypstTest.greet\"))")

                    # Verify native Typst content is preserved
                    @test contains(enhanced_content, "#table(")
                    @test contains(enhanced_content, "#align(center)")
                else
                    # For other platforms, verify PDF was created
                    pdffile = joinpath(builddir, "EnhancedTypstTest-0.1.0.pdf")
                    @test isfile(pdffile)
                    @test filesize(pdffile) > 1000
                end
            end
        else
            @warn "Enhanced Typst fixture not found at $fixture_dir, skipping test"
        end
    end

    @testset "Link Edge Cases (PageLink without fragment)" begin
        fixture_dir = joinpath(@__DIR__, "fixtures", "link_edge_cases")

        if isdir(fixture_dir)
            mktempdir() do tmpdir
                # Copy fixture to temporary directory
                cp(fixture_dir, joinpath(tmpdir, "link_edge_cases"))
                test_dir = joinpath(tmpdir, "link_edge_cases")

                # Run makedocs
                cd(test_dir) do
                    include(joinpath(test_dir, "make.jl"))
                end

                builddir = joinpath(test_dir, "build")
                @test isdir(builddir)

                # Check for platform="none"
                if PLATFORM == "none"
                    typfile = joinpath(builddir, "LinkEdgeCasesTest.typ")
                    @test isfile(typfile)

                    content = read(typfile, String)

                    # Test 1: Page-level labels exist for pages WITHOUT headings
                    @test contains(content, "#label(\"no_heading.md#__page__\")")
                    @test contains(content, "#label(\"empty.md#__page__\")")
                    @test contains(content, "#label(\"only_content.md#__page__\")")

                    # Test 2: Links to pages WITH headings use first heading
                    @test contains(content, "link(label(\"normal.md#Normal-Page\"))")
                    @test contains(content, "link(label(\"multiple.md#Multiple-Headings\"))")
                    @test contains(content, "link(label(\"nested/deep.md#Nested-Deep-Page\"))")

                    # Test 3: Links to pages WITHOUT headings use page label
                    @test contains(content, "link(label(\"no_heading.md#__page__\"))")
                    @test contains(content, "link(label(\"empty.md#__page__\"))")
                    @test contains(content, "link(label(\"only_content.md#__page__\"))")

                    # Test 4: Explicit fragment references still work
                    @test contains(content, "link(label(\"normal.md#Second-Section\"))")

                    # Test 5: Verify links are generated (not just text)
                    # Should NOT have pattern "][text]" which indicates broken link
                    @test !contains(content, "][Normal Page]")
                    @test !contains(content, "][No Heading Page]")
                else
                    # For other platforms, verify PDF was created
                    pdffile = joinpath(builddir, "LinkEdgeCasesTest.pdf")
                    @test isfile(pdffile)
                    @test filesize(pdffile) > 1000
                end
            end
        else
            @warn "Link Edge Cases fixture not found at $fixture_dir, skipping test"
        end
    end
end

@info "Typst backend tests ($PLATFORM) completed successfully!"
