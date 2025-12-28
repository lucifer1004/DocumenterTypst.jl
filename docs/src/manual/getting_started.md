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

### Directory Structure

```
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

### Docker

```julia
format = DocumenterTypst.Typst(platform = "docker")
```

Requires Docker installed.

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
