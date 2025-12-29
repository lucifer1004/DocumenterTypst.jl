# DocumenterTypst.jl

[![CI](https://github.com/lucifer1004/DocumenterTypst.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/lucifer1004/DocumenterTypst.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/lucifer1004/DocumenterTypst.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/lucifer1004/DocumenterTypst.jl)

A [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) plugin for generating documentation in Typst/PDF format.

## Features

- **Fast**: < 60s for `The Julia Language` (Julia doc) (2000+ pages, measured on Apple M4 Max)
- **Math**: LaTeX (via [mitex](https://github.com/mitex-rs/mitex)) + native Typst syntax
- **Platforms**: Typst_jll (default) | native | none
- **Markdown**: Full Documenter support

## Installation

```julia
using Pkg
Pkg.add("DocumenterTypst")
```

## Quick Start

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

## Configuration Options

```julia
DocumenterTypst.Typst(
    platform = "typst",         # "typst" | "native" | "none"
    version = "1.0.0",          # PDF filename: MyPackage-1.0.0.pdf
    typst = nothing,            # Custom path (for platform="native")
    optimize_pdf = true,        # Compress with pdfcpu (60-85% reduction)
    use_system_fonts = true,    # Disable to reduce size
    font_paths = String[],      # Custom font directories
)
```

**Common configurations**:

```julia
# Minimal PDF size
Typst(use_system_fonts = false, optimize_pdf = true)

# Fast development builds
Typst(optimize_pdf = false)

# Custom fonts
Typst(font_paths = ["/path/to/fonts"])

# Native Typst installation
Typst(platform = "native", typst = "/usr/local/bin/typst")
```

## Math Support

LaTeX math (backward compatible):

````markdown
`\alpha + \beta`

```math
\sum_{i=1}^n i = \frac{n(n+1)}{2}
```
````

Typst native syntax:

````markdown
```math typst
sum_(i=1)^n i = (n(n+1))/2
```
````

## Pure Typst Files

Mix `.typ` and `.md` files:

```julia
pages = [
    "Home" => "index.md",
    "Advanced" => "advanced.typ",
    "API" => "api.md",
]
```

**Limitations**: No `@ref` or `@docs` in `.typ` files; images use relative paths.

## Custom Styling

Create `src/assets/custom.typ`:

```typst
#let config = (
  light-blue: rgb("3498db"),
  skip-default-titlepage: true,  // Replace default title
  // ...
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

[Full guide](https://lucifer1004.github.io/DocumenterTypst.jl/stable/manual/styling/)

## Debugging

Save generated Typst source files:

```julia
ENV["DOCUMENTER_TYPST_DEBUG"] = "typst-debug"
makedocs(format = DocumenterTypst.Typst())
# Source files saved to typst-debug/
```

## Comparison with LaTeX

| Feature         | DocumenterTypst  | Documenter (LaTeX) |
| --------------- | ---------------- | ------------------ |
| **Compilation** | < 90s            | Several minutes    |
| **Setup**       | Zero (Typst_jll) | LaTeX distribution |
| **Math**        | LaTeX + Typst    | LaTeX only         |

## Requirements

Julia 1.6+

## Related

- [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl)
- [DocumenterVitepress.jl](https://github.com/LuxDL/DocumenterVitepress.jl)
- [Typst](https://typst.app/)

## Contributing

See [CONTRIBUTING](docs/src/contributing.md). All changes need a `CHANGELOG.md` entry.

```bash
git clone https://github.com/lucifer1004/DocumenterTypst.jl
cd DocumenterTypst.jl
just dev

just test           # Run tests
just docs-typst     # Build PDF
```

Requires [just](https://github.com/casey/just): `brew install just`

## License

MIT License - see [LICENSE](LICENSE).

## Acknowledgments

Built on [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) and [Typst](https://typst.app/). LaTeX math via [mitex](https://github.com/mitex-rs/mitex).
