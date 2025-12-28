# Getting Started

This guide will help you get started with DocumenterTypst.jl.

## Installation

Add DocumenterTypst to your project:

```julia
using Pkg
Pkg.add("DocumenterTypst")
```

## Basic Usage

### Minimal Example

Create a `docs/make.jl` file:

```julia
using Documenter
using DocumenterTypst
using YourPackage

makedocs(
    sitename = "YourPackage",
    authors = "Your Name",
    format = DocumenterTypst.Typst(),
    pages = [
        "Home" => "index.md",
    ]
)
```

Run it:

```bash
julia --project=docs docs/make.jl
```

This generates a PDF in `docs/build/YourPackage.pdf`.

### Optimized Production Build

For production, we recommend these settings to minimize PDF size:

```julia
makedocs(
    sitename = "YourPackage",
    authors = "Your Name",
    format = DocumenterTypst.Typst(
        optimize_pdf = true,        # Enable PDF optimization (default)
        use_system_fonts = false,   # Reduce PDF size (NOT default)
    ),
    pages = [
        "Home" => "index.md",
    ]
)
```

This configuration:

- ✅ Reduces PDF size by 60-85% via automatic optimization
- ✅ Avoids Type 3 emoji fonts that add 40+ MB
- ✅ Produces PDFs comparable in size to LaTeX output

### Directory Structure

```text
YourPackage/
├── src/
│   └── YourPackage.jl
├── docs/
│   ├── Project.toml
│   ├── make.jl
│   └── src/
│       ├── index.md
│       └── api.md
└── test/
```

### docs/Project.toml

```toml
[deps]
Documenter = "e30172f5-a6a5-5a46-863b-614d45cd2de4"
DocumenterTypst = "d7fd56dd-41bc-4b2d-b658-79a5840b2e09"
YourPackage = "..."

[compat]
Documenter = "1.11"
DocumenterTypst = "0.1"
```

## Platform Options

### Default: Typst_jll (Recommended)

```julia
format = DocumenterTypst.Typst(platform = "typst")
```

- ✅ Works everywhere
- ✅ No installation needed
- ✅ Automatic updates

### Native System Typst

```julia
format = DocumenterTypst.Typst(
    platform = "native",
    typst = "/usr/local/bin/typst"  # optional custom path
)
```

Install Typst first:

```bash
# macOS
brew install typst

# Linux
cargo install --git https://github.com/typst/typst

# Windows
winget install --id Typst.Typst
```

### Source Only (No Compilation)

```julia
format = DocumenterTypst.Typst(platform = "none")
```

Generates `.typ` source without compiling to PDF. Useful for:

- Debugging
- Custom pipelines
- Testing

## Adding Version Numbers

```julia
format = DocumenterTypst.Typst(version = "1.0.0")
```

Output: `YourPackage-1.0.0.pdf`

## Multiple Output Formats

Generate both HTML and PDF:

```julia
makedocs(
    sitename = "YourPackage",
    format = Documenter.HTML(...),
    ...
)

# Then generate PDF separately
makedocs(
    sitename = "YourPackage",
    format = DocumenterTypst.Typst(),
    ...
)
```

## Next Steps

- [Configuration Options](configuration.md)
- [Math Support](math.md)
- [Custom Styling](styling.md)

## Using Pure Typst Files

You can include existing `.typ` files directly in your documentation alongside Markdown files:

```julia
makedocs(
    sitename = "MyPackage",
    format = DocumenterTypst.Typst(),
    pages = [
        "Home" => "index.md",           # Markdown (converted)
        "Manual" => "manual.typ",       # Pure Typst (included as-is)
        "API" => [
            "Overview" => "api/index.md",
            "Reference" => "api/ref.typ",  # Nested Typst file
        ],
    ]
)
```

### How It Works

**Heading Levels**: Automatically adjusted using Typst's `offset` parameter

```typst
// In api/ref.typ (at depth 3 in pages config)
= API Reference    // Becomes level 4
== Functions       // Becomes level 5
```

The system calculates the correct offset based on:

- The file's position in the `pages` hierarchy (depth)
- Whether a title is specified in the pages config

**Resource Paths**: Preserved via `#include`

```typst
// In src/manual/guide.typ
#image("../assets/logo.png")  // Works correctly ✓
#image("diagrams/flow.svg")   // Relative to the .typ file location ✓
```

Documenter copies your entire `src/` directory to the build directory, so all relative paths are preserved when using `#include`.

**Page Breaks**: Level 1-2 headings in `.typ` files automatically get page breaks, consistent with `.md` files.

### Use Cases

- **Existing Typst documentation**: Integrate without conversion
- **Advanced layouts**: Use Typst features not available in Markdown (grid, place, custom layouts)
- **Complex tables**: Leverage Typst's powerful table system
- **Mathematical content**: Use native Typst math syntax throughout

### Limitations

- `.typ` files are **not processed by Documenter** (no docstring extraction, no Markdown parsing)
- Content is **only included in Typst/PDF output**, not HTML builds
- Documenter's cross-reference system doesn't index `.typ` content (use native Typst references within `.typ` files)

### Example

Create `docs/src/advanced.typ`:

```typst
= Advanced Topics

This section uses pure Typst for advanced formatting.

== Custom Layout

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
  [
    Left column content
  ],
  [
    Right column content
  ]
)

== Mathematical Proofs

$ sum_(i=1)^n i = (n(n+1))/2 $

This is pure Typst math syntax, no LaTeX conversion needed.
```

Then reference it in `make.jl`:

```julia
pages = [
    "Home" => "index.md",
    "Advanced" => "advanced.typ",  # Pure Typst file
]
```
