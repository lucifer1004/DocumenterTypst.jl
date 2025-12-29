using Documenter
using DocumenterTypst

# Documentation builder for DocumenterTypst.jl
#
# Usage:
#   julia --project=docs docs/make.jl [options]
#
# Options:
#   typst           Build Typst format (PDF via Typst compiler)
#   (none)          Build HTML format (default)
#
#   For Typst builds, additional options:
#     native        Use system-installed typst compiler
#     none          Generate .typ file only, skip compilation
#
#   Common options:
#     local         Build locally without prettified URLs
#     linkcheck     Check external links
#     strict=false  Treat warnings as warnings (not errors)
#     doctest=only  Only run doctests
#
# Examples:
#   julia --project=docs docs/make.jl
#   julia --project=docs docs/make.jl typst
#   julia --project=docs docs/make.jl typst native
#   julia --project=docs docs/make.jl local

# The DOCSARGS environment variable can be used to pass additional arguments to make.jl.
if haskey(ENV, "DOCSARGS")
    for arg in split(ENV["DOCSARGS"])
        (arg in ARGS) || push!(ARGS, arg)
    end
end

# Generate a Documenter-friendly changelog from CHANGELOG.md
Changelog = Base.get_extension(Documenter, :DocumenterChangelogExt)
if !isnothing(Changelog)
    Changelog.generate(
        Changelog.CommonMark(),
        joinpath(@__DIR__, "..", "CHANGELOG.md"),
        joinpath(@__DIR__, "src", "release-notes.md");
        repo = "lucifer1004/DocumenterTypst.jl"
    )
end

# Determine output format based on arguments
output_format = if "typst" in ARGS
    :typst
else
    :html
end

makedocs(;
    modules = [DocumenterTypst],
    sitename = "DocumenterTypst.jl",
    authors = "Gabriel Wu and contributors",
    checkdocs = :exports,
    format = if output_format == :typst
        # Typst format: determine compilation platform
        typst_platform = if "native" in ARGS
            "native"
        elseif "none" in ARGS
            "none"
        else
            "typst"  # Default: use Typst_jll
        end

        # Get version from Project.toml
        project_toml = joinpath(@__DIR__, "..", "Project.toml")
        version = if isfile(project_toml)
            using TOML: TOML
            TOML.parsefile(project_toml)["version"]
        else
            "dev"
        end

        DocumenterTypst.TypstWriter.Typst(; platform = typst_platform, version = version)
    else
        # HTML format
        Documenter.HTML(;
            prettyurls = (!("local" in ARGS)),
            canonical = "https://lucifer1004.github.io/DocumenterTypst.jl",
            assets = String[],
            repolink = "https://github.com/lucifer1004/DocumenterTypst.jl"
        )
    end,
    build = output_format == :typst ? "build-typst" : "build",
    linkcheck = "linkcheck" in ARGS,
    warnonly = ("strict=false" in ARGS),
    doctest = ("doctest=only" in ARGS) ? :only : true,
    pages = [
        "Home" => "index.md",
        "Manual" => [
            "Getting Started" => "manual/getting_started.md",
            "Configuration" => "manual/configuration.md",
            "Math Support" => "manual/math.md",
            "Custom Styling" => "manual/styling.md",
            "Troubleshooting" => "manual/troubleshooting.md",
        ],
        "Examples" => [
            "Advanced Features" => "examples/advanced.md",
            "Migration from LaTeX" => "examples/migration.md",
        ],
        "API Reference" => "api/reference.md",
        "Release Notes" => "release-notes.md",
        "Contributing" => "contributing.md",
    ]
)

if output_format == :typst
    # Deploy Typst PDF to gh-pages-typst branch
    mkpath(joinpath(@__DIR__, "build-typst", "commit"))
    let files = readdir(joinpath(@__DIR__, "build-typst"))
        for f in files
            if startswith(f, "DocumenterTypst") && endswith(f, ".pdf")
                mv(
                    joinpath(@__DIR__, "build-typst", f),
                    joinpath(@__DIR__, "build-typst", "commit", f)
                )
            end
        end
    end
    deploydocs(;
        repo = "github.com/lucifer1004/DocumenterTypst.jl",
        target = "build-typst/commit",
        branch = "gh-pages-typst",
        forcepush = true
    )
elseif !("linkcheck" in ARGS)
    # Deploy HTML to gh-pages branch (skip during linkcheck)
    deploydocs(;
        repo = "github.com/lucifer1004/DocumenterTypst.jl",
        devbranch = "main",
        push_preview = true
    )
end
