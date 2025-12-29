# API Reference

```@meta
CurrentModule = DocumenterTypst
```

DocumenterTypst.jl provides a Documenter.jl plugin for generating documentation in Typst/PDF format.

```@docs
DocumenterTypst
```

## Exported Types

```@docs
Typst
```

## Internal Modules

```@docs
DocumenterTypst.TypstWriter
```

## Usage

The main export from DocumenterTypst is the `Typst` type, which is used as the `format` argument to `makedocs`:

```julia
using Documenter
using DocumenterTypst

makedocs(
    sitename = "MyPackage",
    authors = "Author Name",
    format = DocumenterTypst.Typst(),
    pages = [
        "Home" => "index.md",
        "Guide" => "guide.md",
    ]
)
```

For detailed configuration options, see the [Configuration Guide](../manual/configuration.md).

## Documenter Integration

DocumenterTypst integrates with Documenter.jl through the format plugin system.

For complete integration details and all `makedocs` options, see the [Configuration Guide](../manual/configuration.md).

## Implementation Details

The package consists of two modules:

- **`DocumenterTypst`**: The main module (this is what you `using`)
- **`DocumenterTypst.TypstWriter`**: Internal rendering engine

!!! note "Internal APIs"
The `TypstWriter` module is not part of the public API and may change without notice.
If you need to extend or customize the Typst rendering, please open an issue to discuss
making specific APIs public.

## See Also

- [Documenter.jl Documentation](https://documenter.juliadocs.org/) - Main documentation generator
- [Typst Documentation](https://typst.app/docs/) - Typst typesetting system
- [Getting Started Guide](../manual/getting_started.md) - Quick start guide
- [Configuration Guide](../manual/configuration.md) - Detailed configuration options
