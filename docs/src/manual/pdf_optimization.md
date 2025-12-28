# PDF Size Optimization

DocumenterTypst provides automatic PDF optimization to reduce file sizes while maintaining quality.

## Quick Start

For minimal PDF size:

```julia
makedocs(
    format = DocumenterTypst.Typst(
        optimize_pdf = true,        # Enable optimization (default)
        use_system_fonts = false,   # Avoid bloated system fonts
    )
)
```

## PDF Optimization (`optimize_pdf`)

Automatically compresses and optimizes the generated PDF. **Default: `true`**

```julia
# Enable (recommended for production)
format = DocumenterTypst.Typst(optimize_pdf = true)

# Disable (faster builds during development)
format = DocumenterTypst.Typst(optimize_pdf = false)
```

The optimizer shows before/after statistics:

```text
Info: TypstWriter: optimizing PDF with pdfcpu...
└   size_before = "42.79 MB"

Info: TypstWriter: PDF optimization completed.
│   size_after = "15.23 MB"
│   reduction = "64.4%"
└   time = "1.85s"
```

## System Font Control (`use_system_fonts`)

Controls whether Typst can use system-installed fonts. **Default: `true`** (for backward compatibility)

System fonts, especially emoji fonts, can significantly increase PDF size. Setting this to `false` prevents this issue.

```julia
# Default (backward compatible)
format = DocumenterTypst.Typst(use_system_fonts = true)

# Recommended for production (smaller PDFs)
format = DocumenterTypst.Typst(use_system_fonts = false)
```

**Impact**: Can reduce PDF size by 40+ MB for large documents like the Julia Doc.

## Recommended Configurations

### Production

```julia
makedocs(
    format = DocumenterTypst.Typst(
        optimize_pdf = true,
        use_system_fonts = false,
    )
)
```

Produces optimized, minimal-size PDFs.

### Development

```julia
makedocs(
    format = DocumenterTypst.Typst(
        platform = "none",        # Skip compilation
        optimize_pdf = false,
    ),
    doctest = false
)
```

Fastest iteration - only generates `.typ` source.

## Troubleshooting

### PDF Still Too Large?

1. Check that both optimization settings are enabled
2. Verify your images are compressed
3. Consider reducing the number of fonts used

### Build Too Slow?

Disable optimization during development:

```julia
format = DocumenterTypst.Typst(optimize_pdf = false)
```

## See Also

- [Configuration](configuration.md) - Full configuration reference
- [Getting Started](getting_started.md) - Basic usage
- [Troubleshooting](troubleshooting.md) - Common issues
