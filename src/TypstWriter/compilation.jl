# ============================================================================
# Typst compilation backends
# ============================================================================
#
# This module handles the compilation of .typ files to PDF using different
# backend strategies (native typst, Typst_jll, or no compilation).
#
# Key components:
# - TypstCompiler type hierarchy (polymorphic compilation backends)
# - compile() methods for each backend
# - optimize_pdf() for post-compilation optimization
# - compile_typ() main entry point

"""
    optimize_pdf(pdf_file::String; verbose::Bool=false) -> Bool

Optimize PDF file size using pdfcpu.
Compresses uncompressed streams and optimizes the PDF structure.

Typically reduces file size by 60-85% for Typst-generated PDFs by:
- Compressing all uncompressed content streams
- Optimizing object structure
- Deduplicating resources

Returns true on success, false on failure (with warning logged).
"""
function optimize_pdf(pdf_file::String; verbose::Bool = false)
    try
        # Get original file size
        size_before = filesize(pdf_file)
        size_before_mb = size_before / (1024 * 1024)

        @info "TypstWriter: optimizing PDF with pdfcpu..." size_before = "$(round(size_before_mb; digits = 2)) MB"

        # pdfcpu optimize command with timing
        opt_time = @elapsed begin
            cmd = `$(pdfcpu()) optimize $(pdf_file)`
            if verbose
                run(cmd)
            else
                # Redirect output to avoid clutter
                run(pipeline(cmd; stdout = devnull, stderr = devnull))
            end
        end

        # Get optimized file size
        size_after = filesize(pdf_file)
        size_after_mb = size_after / (1024 * 1024)
        reduction_pct = round((1 - size_after / size_before) * 100; digits = 1)

        @info "TypstWriter: PDF optimization completed." size_after = "$(round(size_after_mb; digits = 2)) MB" reduction = "$(reduction_pct)%" time = "$(round(opt_time; digits = 2))s"
        return true
    catch e
        @warn "PDF optimization failed, using unoptimized version" exception = e
        return false
    end
end

"""
Abstract base type for Typst compilation backends.
Each concrete type implements a specific way to compile .typ files to PDF.
"""
abstract type TypstCompiler end

"""Native system typst executable."""
struct NativeCompiler <: TypstCompiler
    typst_cmd::Cmd
end

"""Typst_jll Julia binary wrapper."""
struct TypstJllCompiler <: TypstCompiler end

"""No-op compiler (only generates .typ source)."""
struct NoOpCompiler <: TypstCompiler end

"""
    get_compiler(settings::Typst) -> TypstCompiler

Factory function to create the appropriate compiler based on settings.
"""
function get_compiler(settings::Typst)
    if settings.platform == "native"
        cmd = settings.typst === nothing ? `typst` : settings.typst
        return NativeCompiler(cmd)
    elseif settings.platform == "typst"
        return TypstJllCompiler()
    elseif settings.platform == "none"
        return NoOpCompiler()
    else
        error("Unknown platform: $(settings.platform)")
    end
end

"""
    compile(compiler::TypstCompiler, fileprefix::String, settings::Typst) -> Bool

Compile the .typ file using the given compiler backend.
Returns true on success, throws on failure.
"""
function compile(c::NativeCompiler, fileprefix::String, settings::Typst)
    Sys.which("typst") === nothing && error("typst command not found")
    @info "TypstWriter: compiling Typst to PDF (native)..."

    # Build compile command with optional flags
    cmd = `$(c.typst_cmd) compile`

    # Add font paths
    for path in settings.font_paths
        cmd = `$cmd --font-path $path`
    end

    # Add system fonts flag
    if !settings.use_system_fonts
        cmd = `$cmd --ignore-system-fonts`
    end

    cmd = `$cmd $(fileprefix).typ`

    compile_time = @elapsed piperun(cmd; clearlogs = true)
    @info "TypstWriter: Typst compilation completed." time = "$(round(compile_time; digits = 2))s"
    return true
end

function compile(c::TypstJllCompiler, fileprefix::String, settings::Typst)
    @info "TypstWriter: compiling Typst to PDF (Typst_jll)..."

    # Build compile command with optional flags
    cmd = `$(typst_exe()) compile`

    # Add font paths
    for path in settings.font_paths
        cmd = `$cmd --font-path $path`
    end

    # Add system fonts flag
    if !settings.use_system_fonts
        cmd = `$cmd --ignore-system-fonts`
    end

    cmd = `$cmd $(fileprefix).typ`

    compile_time = @elapsed piperun(cmd; clearlogs = true)
    @info "TypstWriter: Typst compilation completed." time = "$(round(compile_time; digits = 2))s"
    return true
end

function compile(::NoOpCompiler, ::String, ::Typst)
    @info "TypstWriter: skipping compilation (platform=none)."
    return true
end

"""
    compile_typ(doc::Document, settings::Typst, fileprefix::String) -> Bool

Main entry point for Typst compilation. 
Selects the appropriate compiler, handles errors uniformly, and optionally optimizes PDF.
"""
function compile_typ(::Documenter.Document, settings::Typst, fileprefix::String)
    compiler = get_compiler(settings)

    try
        success = compile(compiler, fileprefix, settings)

        # Apply PDF optimization if enabled and compilation succeeded
        if success && settings.optimize_pdf && settings.platform != "none"
            pdf_file = "$(fileprefix).pdf"
            if isfile(pdf_file)
                verbose = "--verbose" in ARGS || get(ENV, "DOCUMENTER_VERBOSE", "false") == "true"
                optimize_pdf(pdf_file; verbose = verbose)
            end
        end

        return success
    catch err
        logs = cp(pwd(), mktempdir(; cleanup = false); force = true)
        @error "TypstWriter: compilation failed. " *
            "Logs and partial output can be found in $(Documenter.locrepr(logs))." exception = err
        return false
    end
end

function piperun(cmd; clearlogs = false)
    verbose = "--verbose" in ARGS || get(ENV, "DOCUMENTER_VERBOSE", "false") == "true"
    return run(
        if verbose
            cmd
        else
            pipeline(
                cmd;
                stdout = "TypstWriter.stdout",
                stderr = "TypstWriter.stderr",
                append = (!clearlogs)
            )
        end,
    )
end
