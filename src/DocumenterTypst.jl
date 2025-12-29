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

# Re-export the Typst format for convenience
export Typst

# Include the main writer module
include("TypstWriter/TypstWriter.jl")
using .TypstWriter: Typst

end # module
