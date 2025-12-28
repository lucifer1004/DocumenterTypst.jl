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
    format = DocumenterTypst.Typst(
        platform = "typst",  # Compilation backend
        version = "1.0.0",   # Version for PDF filename
    ),
    pages = [
        "Home" => "index.md",
        "Guide" => "guide.md",
    ]
)
```

## Configuration Options

### Platform Options

- **`"typst"`** (default): Uses `Typst_jll` for automatic cross-platform support
- **`"native"`**: Uses system-installed `typst` executable
- **`"docker"`**: Docker-based compilation for reproducible builds
- **`"none"`**: Generate `.typ` source only, skip PDF compilation

### Additional Options

- **`version`**: Semantic version string appended to the PDF filename (e.g., `"1.0.0"` produces `MyPackage-1.0.0.pdf`)
- **`typst`**: Custom path to `typst` executable (only for `platform="native"`)

## Documenter Integration

DocumenterTypst integrates with Documenter.jl through the format plugin system. The following `makedocs` options are used:

- **`sitename`**: Document title (appears in PDF metadata and title page)
- **`authors`**: Author names (appears in PDF metadata)
- **`pages`**: Document structure (converted to Typst headings and sections)

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
