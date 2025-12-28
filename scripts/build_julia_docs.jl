#!/usr/bin/env julia
#
# Build Julia official documentation with Typst backend
#
# This script:
# 1. Clones the Julia repository to a temporary directory (or uses existing)
# 2. Converts LaTeX assets (logo, splash) to SVG using command-line tools
# 3. Sets up Documenter environment
# 4. Generates a modified make.jl that uses DocumenterTypst format
# 5. Produces PDF documentation with custom Julia cover page
#
# The script reads Julia's original make.jl and programmatically modifies it to:
# - Replace the format definition (HTML/LaTeX → DocumenterTypst.Typst)
# - Add custom preamble with Julia branding (cover, styles)
# - Update output path from "pdf" to "typst"
#
# Usage:
#   # Clone to temp directory
#   julia scripts/build_julia_docs.jl
#
#   # Use existing Julia repository
#   julia scripts/build_julia_docs.jl --julia-repo=/path/to/julia
#
#   # Specify platform
#   julia scripts/build_julia_docs.jl --platform=none
#
#   # Combine options
#   julia scripts/build_julia_docs.jl --julia-repo=../julia --platform=native
#
# Environment variables:
#   TYPST_PLATFORM - Compilation backend: "native", "typst", "none" (default: "native")
#

using Dates, Pkg

const DOCUMENTER_ROOT = dirname(@__DIR__)

"""
    check_prerequisites()

Check that all required system commands are available.
"""
function check_prerequisites()
    @info "Checking prerequisites..."

    required_cmds = ["git", "pdflatex", "pdf2svg"]
    missing_cmds = String[]

    for cmd in required_cmds
        if Sys.which(cmd) === nothing
            push!(missing_cmds, cmd)
        end
    end

    if !isempty(missing_cmds)
        error(
            """
            Missing required commands: $(join(missing_cmds, ", "))

            Install them:
              - macOS:   brew install basictex pdf2svg
              - Ubuntu:  apt-get install texlive-latex-base texlive-pictures pdf2svg
              - Arch:    pacman -S texlive-core pdf2svg
            """
        )
    end

    return @info "✓ All prerequisites available"
end

"""
    clone_julia_repo(dest_dir::String)

Clone the Julia repository to the specified directory.
Uses the commit corresponding to the currently running Julia version.
"""
function clone_julia_repo(dest_dir)
    @info "Cloning Julia repository..."
    @info "Julia version: $(VERSION)"
    @info "Commit: $(Base.GIT_VERSION_INFO.commit_short)"

    # Use the commit corresponding to the current Julia binary
    commit = Base.GIT_VERSION_INFO.commit

    return try
        run(`git clone --depth=1 https://github.com/JuliaLang/julia.git $(dest_dir)`)
        cd(dest_dir) do
            run(`git fetch --depth=1 origin $(commit)`)
            run(`git checkout $(commit)`)
        end

        @info "✓ Julia repository cloned: $(dest_dir)"
    catch e
        @error "Failed to clone Julia repository" exception = e
        rethrow()
    end
end

"""
    convert_latex_assets(julia_repo::String) -> String

Convert Julia's LaTeX assets (logo.tex, cover-splash.tex) to SVG format.
Uses the convert_latex_assets.sh script.

Returns the path to the output directory containing SVG files.
"""
function convert_latex_assets(julia_repo)
    @info "Converting LaTeX assets to SVG..."

    julia_assets = joinpath(julia_repo, "doc", "src", "assets")
    output_dir = joinpath(DOCUMENTER_ROOT, "assets", "typst", "julia")
    mkpath(output_dir)

    convert_script = joinpath(DOCUMENTER_ROOT, "scripts", "convert_latex_assets.sh")

    try
        run(`bash $(convert_script) $(julia_assets) $(output_dir)`)
        @info "✓ LaTeX assets converted"
    catch e
        @error "Failed to convert LaTeX assets" exception = e
        rethrow()
    end

    return output_dir
end

"""
    setup_documenter(julia_repo::String)

Set up the Documenter environment in the Julia repository.
Develops the local Documenter.jl package into Julia's doc environment.
"""
function setup_documenter(julia_repo)
    @info "Setting up Documenter environment..."

    project_path = joinpath(julia_repo, "deps", "jlutilities", "documenter")

    if !isdir(project_path)
        error("Documenter project not found at: $(project_path)")
    end

    @info "Using local Documenter: $(DOCUMENTER_ROOT)"

    run(
        ```
        $(Base.julia_cmd())
        --project=$(project_path)
        -e 'using Pkg; Pkg.develop(path=ARGS[1]); Pkg.instantiate()'
        --
        $(DOCUMENTER_ROOT)
        ```
    )

    return @info "✓ Documenter environment ready"
end

"""
    create_typst_make_script(julia_repo::String, platform::String, typst_assets::String) -> String

Create a modified make.jl script that uses Typst format with custom cover.

This function reads the Julia repository's make.jl and modifies it to use
DocumenterTypst format instead of HTML/LaTeX. It also copies the custom
Typst assets (cover, styles, SVG graphics) to the Julia doc/src/assets directory.

Returns the path to the generated script.
"""
function create_typst_make_script(julia_repo, platform, typst_assets)
    @info "Creating Typst build script from Julia's make.jl..."

    doc_path = joinpath(julia_repo, "doc")
    original_make_path = joinpath(doc_path, "make.jl")

    if !isfile(original_make_path)
        error("make.jl not found at: $(original_make_path)")
    end

    @info "Reading original make.jl..."
    original_make = read(original_make_path, String)

    # Copy custom Typst assets to Julia doc/src/assets/
    @info "Copying Typst assets to Julia doc directory..."
    julia_assets_dir = joinpath(doc_path, "src", "assets")
    mkpath(julia_assets_dir)

    # Copy SVG files to Julia assets directory
    # These will be included in the build directory by Documenter
    for file in ["julia-logo.svg", "julia-splash.svg"]
        src = joinpath(typst_assets, file)
        dst = joinpath(julia_assets_dir, file)
        if isfile(src)
            cp(src, dst; force = true)
            @info "  ✓ Copied $(file)"
        else
            @warn "  ⚠ File not found: $(src)"
        end
    end

    # Create a custom.typ with Julia branding and cover page
    # Images will be available at assets/ relative to the .typ file
    custom_typ_content = """
    // Julia Documentation Custom Typst Styles
    // Auto-generated by build_julia_docs.jl

    // Cover page with Julia branding
    #page(
        margin: (left: 2cm, right: 2cm, bottom: 3cm, top: 2cm),
        header: none,
        footer: none,
    )[
        // Background splash pattern
        #place(top + left, dx: 0pt, dy: 0pt)[
            #box(width: 100%, height: 100%)[
                #image("assets/julia-splash.svg", width: 100%)
            ]
        ]
        
        #v(2.2cm)
        
        #align(center)[
            // Main title
            #text(
                size: 48pt, 
                weight: "bold", 
                fill: black
            )[The Julia Language]
            
            #v(1fr)
            
            // Julia Logo
            #image("assets/julia-logo.svg", width: 150pt)
            
            #v(1.5cm)
            
            // Version number
            #text(
                size: 36pt,
                weight: "semibold"
            )[V$(VERSION)]
            
            #v(1fr)
            
            // Authors
            #text(size: 24pt)[The Julia Project]
            
            #v(0.5cm)
            
            // Build date
            #text(size: 20pt)[
                #datetime.today().display("[month repr:long] [day], [year]")
            ]
            
            #v(2cm)
        ]

        #pagebreak()
    ]

    #let config = (skip-default-titlepage: true)
    """

    write(joinpath(julia_assets_dir, "custom.typ"), custom_typ_content)
    @info "  ✓ Generated custom.typ with Julia cover and branding"

    # Find the format definition and replace it
    # Pattern: const format = if render_pdf ... end
    format_pattern = r"const format = if render_pdf.*?^end"ms

    typst_format_code = """
    const format = if render_pdf
        import DocumenterTypst
        DocumenterTypst.Typst(
            platform = "$(platform)",
            use_system_fonts = false,
        )
    else
        Documenter.HTML(
            prettyurls = ("deploy" in ARGS),
            canonical = ("deploy" in ARGS) ? "https://docs.julialang.org/en/v1/" : nothing,
            assets = [
                "assets/julia-manual.css",
                "assets/julia.ico",
            ],
            analytics = "UA-28835595-6",
            collapselevel = 1,
            sidebar_sitename = false,
            ansicolor = true,
            size_threshold = 800 * 2^10, # 800 KiB
            size_threshold_warn = 200 * 2^10, # the manual has quite a few large pages, so we warn at 200+ KiB only
            inventory_version = VERSION,
        )
    end"""

    modified_make = replace(original_make, format_pattern => typst_format_code; count = 1)

    # Update output_path to use "typst" instead of "pdf" for render_pdf case
    output_path_pattern = r"const output_path = joinpath\(buildrootdoc, \"_build\", \(render_pdf \? \"pdf\" : \"html\"\), \"en\"\)"
    modified_make = replace(
        modified_make,
        output_path_pattern =>
            """const output_path = joinpath(buildrootdoc, "_build", (render_pdf ? "typst" : "html"), "en")"""
    )

    # Remove the placeholder comment at the end if it exists
    placeholder_pattern = r"\n# Override to use Typst format.*\z"s
    modified_make = replace(modified_make, placeholder_pattern => "")

    # Write the modified script
    typst_script = joinpath(doc_path, "make_typst_generated.jl")
    write(typst_script, modified_make)

    @info "✓ Typst build script created: $(typst_script)"

    return typst_script
end

"""
    build_docs(julia_repo::String, typst_script::String)

Build the Julia documentation using the generated Typst script.
"""
function build_docs(julia_repo, typst_script)
    @info "Building Julia documentation..."

    # Build stdlib
    @info "Building julia-stdlib..."
    run(`make -C $(julia_repo) julia-stdlib`)

    # Download dependencies
    @info "Downloading documentation dependencies..."
    run(`make -C $(joinpath(julia_repo, "doc")) deps`)

    # Build documentation with Typst format
    @info "Running Typst build script..."
    project_path = joinpath(julia_repo, "deps", "jlutilities", "documenter")

    return try
        # Pass "pdf" argument to trigger render_pdf = true in the script
        run(
            ```
            $(Base.julia_cmd())
            --project=$(project_path)
            --color=yes
            $(typst_script)
            pdf
            ```
        )

        @info "✓ Documentation build completed"
    catch e
        @error "Documentation build failed" exception = e
        rethrow()
    end
end

"""
    main()

Main entry point for the build script.

Command-line arguments:
  --julia-repo=PATH    Use existing Julia repository instead of cloning
  --platform=PLATFORM  Typst compilation platform (native, typst, none)
  --help              Show this help message

Environment variables:
  TYPST_PLATFORM - Alternative way to specify compilation platform

Examples:
  # Clone Julia repo to temp directory and build
  julia scripts/build_julia_docs.jl

  # Use existing Julia repository
  julia scripts/build_julia_docs.jl --julia-repo=/path/to/julia

  # Specify platform via argument
  julia scripts/build_julia_docs.jl --platform=none

  # Specify platform via environment variable
  TYPST_PLATFORM=native julia scripts/build_julia_docs.jl

  # Combine both
  julia scripts/build_julia_docs.jl --julia-repo=../julia --platform=none
"""
function main()
    # Parse command-line arguments
    julia_repo_path = nothing
    platform = get(ENV, "TYPST_PLATFORM", "typst")
    show_help = false

    for arg in ARGS
        if startswith(arg, "--julia-repo=")
            julia_repo_path = arg[14:end]  # Skip "--julia-repo="
        elseif arg == "--julia-repo" && length(ARGS) > findfirst(==(arg), ARGS)
            # Support both --julia-repo=path and --julia-repo path
            idx = findfirst(==(arg), ARGS)
            julia_repo_path = ARGS[idx + 1]
        elseif startswith(arg, "--platform=")
            platform = arg[12:end]  # Skip "--platform="
        elseif arg in ("--help", "-h")
            show_help = true
        end
    end

    if show_help
        println(@doc main)
        return
    end

    @info """
    ╔═══════════════════════════════════════════════════════════╗
    ║  Julia Documentation Builder (Typst Backend)              ║
    ╚═══════════════════════════════════════════════════════════╝

    Configuration:
      - Julia version: $(VERSION)
      - Typst platform: $(platform)
      - Documenter: $(DOCUMENTER_ROOT)
      - Julia repo: $(isnothing(julia_repo_path) ? "will clone to temp dir" : julia_repo_path)
    """

    check_prerequisites()

    return if isnothing(julia_repo_path)
        # Clone to temporary directory
        mktempdir() do tmpdir
            julia_repo = joinpath(tmpdir, "julia")
            execute_build_pipeline(julia_repo, platform, true)
        end
    else
        # Use existing Julia repository
        julia_repo = abspath(julia_repo_path)

        if !isdir(julia_repo)
            error("Julia repository not found at: $(julia_repo)")
        end

        if !isfile(joinpath(julia_repo, "doc", "make.jl"))
            error("Not a valid Julia repository (doc/make.jl not found): $(julia_repo)")
        end

        @info "Using existing Julia repository: $(julia_repo)"
        execute_build_pipeline(julia_repo, platform, false)
    end
end

"""
    execute_build_pipeline(julia_repo::String, platform::String, should_clone::Bool)

Execute the complete build pipeline.

Arguments:
- `julia_repo`: Path to Julia repository
- `platform`: Typst compilation platform
- `should_clone`: Whether to clone the repository (true) or use existing one (false)
"""
function execute_build_pipeline(julia_repo, platform, should_clone)
    # Clone if needed
    if should_clone
        clone_julia_repo(julia_repo)
    end

    # Convert assets
    typst_assets = convert_latex_assets(julia_repo)

    # Setup environment
    setup_documenter(julia_repo)

    # Create build script
    typst_script = create_typst_make_script(julia_repo, platform, typst_assets)

    # Build documentation
    build_docs(julia_repo, typst_script)

    # Report results
    return report_build_results(julia_repo, platform)
end

"""
    report_build_results(julia_repo::String, platform::String)

Report the build results and output file locations.
"""
function report_build_results(julia_repo, platform)
    build_dir = joinpath(julia_repo, "doc", "_build", "typst", "en")
    return if isdir(build_dir)
        @info ""
        @info "="^70
        @info "Build successful! 🎉"
        @info "="^70

        files = readdir(build_dir)
        typ_files = filter(f -> endswith(f, ".typ"), files)
        pdf_files = filter(f -> endswith(f, ".pdf"), files)

        if !isempty(pdf_files)
            for f in pdf_files
                path = joinpath(build_dir, f)
                size_mb = round(filesize(path) / 1024 / 1024, digits = 2)
                @info "📄 $(f) ($(size_mb) MB)"
                @info "   Location: $(path)"
            end
        elseif !isempty(typ_files)
            @info "📝 Generated .typ source (platform=none)"
            for f in typ_files
                @info "   $(joinpath(build_dir, f))"
            end
        end
    else
        @warn "Build directory not found: $(build_dir)"
        @warn "Checking alternative locations..."

        # Check if HTML build succeeded instead
        html_dir = joinpath(julia_repo, "doc", "_build", "html", "en")
        if isdir(html_dir)
            @info "Found HTML build at: $(html_dir)"
            @info "This might indicate the build used HTML format instead of Typst."
        end
    end
end

# Run if executed as script
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
