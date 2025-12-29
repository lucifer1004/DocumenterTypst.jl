# Getting Started

This guide will get you up and running with DocumenterTypst.jl in under a minute.

## Installation

Add DocumenterTypst to your documentation project:

```julia
using Pkg
Pkg.add("DocumenterTypst")
```

## Minimal Example

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

Create `docs/src/index.md`:

```markdown
# YourPackage

Welcome to the documentation!
```

Run it:

```bash
julia --project=docs docs/make.jl
```

**Output**: `docs/build/YourPackage.pdf`

That's it! You now have a PDF version of your documentation.

## Next Steps

- **[Configuration](configuration.md)** - Customize compilation, add version numbers, optimize PDF size
- **[Custom Styling](styling.md)** - Change colors, fonts, and layout
- **[Math Support](math.md)** - Write mathematical equations
- **[Advanced Features](../examples/advanced.md)** - Multi-format builds, custom templates, CI/CD
- **[Troubleshooting](troubleshooting.md)** - Common issues and solutions

## Common Scenarios

### Add a Version Number

```julia
makedocs(
    format = DocumenterTypst.Typst(version = "1.0.0"),
    ...
)
```

Output: `YourPackage-1.0.0.pdf`

### Multi-Page Documentation

```julia
makedocs(
    pages = [
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "API Reference" => "api.md",
    ],
    ...
)
```

### Generate Both HTML and PDF

Build HTML first, then PDF:

```julia
# Build HTML
makedocs(
    sitename = "YourPackage",
    format = Documenter.HTML(),
    ...
)

# Build PDF separately
makedocs(
    sitename = "YourPackage",
    format = DocumenterTypst.Typst(),
    ...
)
```

See [Advanced Features](../examples/advanced.md) for a complete example.

## Project Structure

Typical documentation layout:

```text
YourPackage/
├── src/
│   └── YourPackage.jl
├── docs/
│   ├── Project.toml          # Documentation dependencies
│   ├── make.jl               # Build script
│   └── src/
│       ├── index.md          # Home page
│       ├── tutorial.md       # User guide
│       └── api.md            # API reference
└── test/
```

Your `docs/Project.toml` should include:

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

DocumenterTypst works with three compilation backends:

| Platform   | Description                            | Use Case           |
| ---------- | -------------------------------------- | ------------------ |
| `"typst"`  | Uses Typst_jll (default, recommended)  | Production, CI/CD  |
| `"native"` | Uses system-installed typst executable | Development        |
| `"none"`   | Generate `.typ` source only            | Testing, debugging |

**Default configuration** (recommended for most users):

```julia
format = DocumenterTypst.Typst()  # Uses Typst_jll automatically
```

**Custom platform**:

```julia
format = DocumenterTypst.Typst(platform = "native")
```

For detailed configuration options, see [Configuration](configuration.md).
