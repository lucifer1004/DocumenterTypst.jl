"""
DocumenterTypst

A Documenter.jl plugin for generating documentation in Typst/PDF format.

# Usage

```julia
using Documenter
using DocumenterTypst

makedocs(
    sitename = "MyPackage",
    format = DocumenterTypst.Typst(),
    pages = [
        "Home" => "index.md",
    ]
)
```

See the documentation for `DocumenterTypst.Typst` for more options.
"""
module DocumenterTypst

using Documenter
import Documenter: Documenter, Builder, Expanders
using Requires: @require

# Re-export the Typst format for convenience
export Typst

# Include the main writer module
include("TypstWriter/TypstWriter.jl")
using .TypstWriter: Typst

# Re-export types and functions needed by extensions
# This allows extensions to use `using DocumenterTypst: Context, typst, ...`
# instead of reaching into the TypstWriter submodule
using .TypstWriter: Context, _print, _println, typst, typstesc

"""
    __init__()

Initialize DocumenterTypst at runtime.

This function:
1. Registers Documenter method overrides (via @eval to avoid precompilation issues)
2. Sets up Requires.jl compatibility for Julia < 1.9 (package extensions)
"""
function __init__()
    # Skip method registration during precompilation (e.g., when extensions are being compiled)
    # ccall(:jl_generating_output, Cint, ()) returns 1 during precompilation, 0 at runtime
    if ccall(:jl_generating_output, Cint, ()) == 0
        # Register Documenter method overrides
        # These must be done at runtime via @eval because method overwriting
        # is not permitted during precompilation
        @eval Documenter.Selectors.runner(
            ::Type{Documenter.Builder.SetupBuildDirectory},
            doc::Documenter.Document
        ) = TypstWriter._setup_build_directory_impl(doc)

        @eval Documenter.Selectors.runner(
            ::Type{Documenter.FormatSelector},
            fmt::TypstWriter.Typst,
            doc::Documenter.Document
        ) = TypstWriter._format_selector_impl(fmt, doc)
    end

    # For Julia < 1.9, use Requires.jl for package extension compatibility
    # On Julia 1.9+, extensions are loaded automatically via Project.toml
    return @static if !isdefined(Base, :get_extension)
        @require DocumenterCitations = "daee34ce-89f3-4625-b898-19384cb65244" include("../ext/DocumenterCitationsExt.jl")
    end
end

end # module
