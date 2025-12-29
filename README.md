# DocumenterTypst.jl

[![CI](https://github.com/lucifer1004/DocumenterTypst.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/lucifer1004/DocumenterTypst.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/lucifer1004/DocumenterTypst.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/lucifer1004/DocumenterTypst.jl)

A [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) plugin for generating documentation in Typst/PDF format.

## Features

- **Fast**: < 60s for Julia documentation (2000+ pages, measured on Apple M4 Max)
- **Zero Setup**: Works out of the box with Typst_jll
- **Math**: LaTeX (via [mitex](https://github.com/mitex-rs/mitex)) + native Typst syntax
- **Full Documenter Support**: All markdown features, cross-references, doctests

## Quick Start

```julia
using Documenter, DocumenterTypst

makedocs(
    sitename = "MyPackage",
    authors = "Your Name",
    format = DocumenterTypst.Typst(),
    pages = ["Home" => "index.md"]
)
```

**Output**: `docs/build/MyPackage.pdf`

See [documentation](https://lucifer1004.github.io/DocumenterTypst.jl/) for details.

## Configuration

```julia
DocumenterTypst.Typst(
    platform = "typst",         # "typst" | "native" | "none"
    version = "1.0.0",          # PDF filename: MyPackage-1.0.0.pdf
    optimize_pdf = true,        # Compress with pdfcpu (60-85% reduction)
    use_system_fonts = false,   # Recommended for smaller PDFs
)
```

**Common configurations**:

```julia
# Minimal PDF size (recommended for production)
format = DocumenterTypst.Typst(
    use_system_fonts = false,
    optimize_pdf = true,
)

# Fast development builds
format = DocumenterTypst.Typst(
    platform = "none",          # Skip compilation
    optimize_pdf = false,
)
```

## Math Support

**LaTeX** (backward compatible):

````markdown
`\alpha + \beta`

```math
\sum_{i=1}^n i = \frac{n(n+1)}{2}
```
````

**Typst** (native):

````markdown
```math typst
sum_(i=1)^n i = (n(n+1))/2
```
````

## Custom Styling

Create `docs/src/assets/custom.typ`:

```typst
#let config = (
  light-blue: rgb("3498db"),
  text-font: ("Times New Roman", "DejaVu Serif"),
  skip-default-titlepage: true,
)

// Custom title page
#page(header: none, footer: none)[
  #align(center)[
    #v(3cm)
    #image("logo.png", width: 150pt)
    #v(2cm)
    #text(size: 48pt)[My Package]
  ]
]
#pagebreak()
```

[Full styling guide](https://lucifer1004.github.io/DocumenterTypst.jl/stable/manual/styling/)

## Pure Typst Files

Mix `.typ` and `.md` files in documentation:

```julia
pages = [
    "Home" => "index.md",
    "Advanced" => "advanced.typ",  # Pure Typst file
    "API" => "api.md",
]
```

## Comparison with LaTeX

| Feature         | DocumenterTypst  | Documenter (LaTeX) |
| --------------- | ---------------- | ------------------ |
| **Compilation** | < 60s            | Several minutes    |
| **Setup**       | Zero (Typst_jll) | LaTeX distribution |
| **Math**        | LaTeX + Typst    | LaTeX only         |
| **Errors**      | Clear            | Often cryptic      |

## Installation

```julia
using Pkg
Pkg.add("DocumenterTypst")
```

**Requirements**: Julia 1.6+

## Documentation

- **[Getting Started](https://lucifer1004.github.io/DocumenterTypst.jl/stable/manual/getting_started/)** - Quick setup guide
- **[Configuration](https://lucifer1004.github.io/DocumenterTypst.jl/stable/manual/configuration/)** - All options explained
- **[Custom Styling](https://lucifer1004.github.io/DocumenterTypst.jl/stable/manual/styling/)** - Customize appearance
- **[Math Support](https://lucifer1004.github.io/DocumenterTypst.jl/stable/manual/math/)** - LaTeX and Typst math
- **[Troubleshooting](https://lucifer1004.github.io/DocumenterTypst.jl/stable/manual/troubleshooting/)** - Common issues

## Debugging

Save generated Typst source files:

```bash
export DOCUMENTER_TYPST_DEBUG="typst-debug"
julia docs/make.jl
# Source files saved to typst-debug/
```

## Contributing

See [Contributing Guide](docs/src/contributing.md).

**Development setup**:

```bash
git clone https://github.com/lucifer1004/DocumenterTypst.jl
cd DocumenterTypst.jl
just dev         # Install dependencies
just test        # Run tests
just docs-typst  # Build PDF documentation
```

Requires [just](https://github.com/casey/just): `brew install just` (macOS) or see [installation](https://github.com/casey/just#installation).

## License

MIT License - see [LICENSE](LICENSE).

## Acknowledgments

Built on [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) and [Typst](https://typst.app/). LaTeX math via [mitex](https://github.com/mitex-rs/mitex).

## Related Projects

- [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) - Julia documentation generator
- [DocumenterVitepress.jl](https://github.com/LuxDL/DocumenterVitepress.jl) - Vitepress backend for Documenter
- [Typst](https://typst.app/) - Modern typesetting system
