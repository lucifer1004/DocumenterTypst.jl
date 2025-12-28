# DocumenterTypst.jl

[![CI](https://github.com/lucifer1004/DocumenterTypst/actions/workflows/CI.yml/badge.svg)](https://github.com/lucifer1004/DocumenterTypst/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/lucifer1004/DocumenterTypst/branch/main/graph/badge.svg)](https://codecov.io/gh/lucifer1004/DocumenterTypst)

A [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) plugin for generating documentation in Typst/PDF format.

## Features

- **Fast Compilation**: Significantly faster than LaTeX-based PDF generation (< 90s for large projects like Julia documentation on M4 Max)
- **High-Quality Output**: Professional PDF output with modern typography
- **Flexible Math Support**:
  - LaTeX math via [mitex](https://github.com/mitex-rs/mitex) for backward compatibility
  - Native Typst math syntax for new projects
- **Multiple Compilation Backends**:
  - `typst`: Typst_jll (default, works on all platforms)
  - `native`: System-installed Typst compiler
  - `docker`: Docker-based compilation
  - `none`: Generate `.typ` source only
- **Rich Markdown Support**: Full support for Documenter's extended Markdown features

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

### Basic Options

```julia
DocumenterTypst.Typst(
    platform = "typst",  # Compilation backend: "typst", "native", "docker", "none"
    version = "1.0.0",   # Version string for the PDF filename
    typst = nothing,     # Custom path to typst executable (for platform="native")
)
```

### Platform Options

#### `platform="typst"` (Default)

Uses [Typst_jll.jl](https://github.com/JuliaBinaryWrappers/Typst_jll.jl), a Julia binary wrapper that provides the Typst compiler automatically across all platforms.

```julia
format = DocumenterTypst.Typst(platform = "typst")
```

#### `platform="native"`

Uses a system-installed `typst` executable. You can specify a custom path:

```julia
format = DocumenterTypst.Typst(
    platform = "native",
    typst = "/usr/local/bin/typst"  # or `typst` Cmd object
)
```

#### `platform="docker"`

Compiles using Docker. Requires `docker` to be available in `PATH`.

```julia
format = DocumenterTypst.Typst(platform = "docker")
```

#### `platform="none"`

Generates only the `.typ` source file without compiling to PDF. Useful for:

- Debugging Typst output
- Custom compilation pipelines
- Testing

```julia
format = DocumenterTypst.Typst(platform = "none")
```

## Math Support

### LaTeX Math (via mitex)

Backward compatible with existing Documenter documentation:

````markdown
Inline: `\alpha + \beta`

Display:

```math
\sum_{i=1}^n i = \frac{n(n+1)}{2}
```
````

### Native Typst Math

For new projects, you can use Typst's native math syntax:

````markdown
```math typst
sum_(i=1)^n i = (n(n+1))/2
```
````

## Custom Styling

You can customize the PDF appearance by creating a custom template:

1. Create `src/assets/custom.typ` in your documentation source directory
2. Add your customizations:

```typst
// Override default colors
#let config = (
  light-blue: rgb("3498db"),
  dark-blue: rgb("2c3e50"),
  // ... other customizations
)
```

## Advanced Features

### Custom Template Location

The package looks for `src/assets/custom.typ` by default. If it doesn't exist, an empty template is used.

### Debugging

Set the `DOCUMENTER_TYPST_DEBUG` environment variable to save the generated Typst source files:

```julia
ENV["DOCUMENTER_TYPST_DEBUG"] = "typst-debug"
makedocs(format = DocumenterTypst.Typst())
# Source files will be saved to typst-debug/ in your project root
```

### Version in Filename

If you specify a semantic version, it will be appended to the output PDF filename:

```julia
format = DocumenterTypst.Typst(version = "1.2.3")
# Output: MyPackage-1.2.3.pdf
```

## Comparison with LaTeX Backend

| Feature              | DocumenterTypst    | Documenter (LaTeX)          |
| -------------------- | ------------------ | --------------------------- |
| **Compilation Time** | < 90s (Julia docs) | Several minutes             |
| **Setup Complexity** | None (Typst_jll)   | Requires LaTeX distribution |
| **Output Quality**   | High               | High                        |
| **Math Support**     | LaTeX + Typst      | LaTeX                       |
| **Customization**    | Typst templates    | LaTeX templates             |

## Requirements

- Julia 1.10 or later
- Documenter.jl 1.11 or later
- Typst_jll.jl (automatically installed) or a system Typst installation

## Related Packages

- [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) - The main documentation generator
- [DocumenterVitepress.jl](https://github.com/LuxDL/DocumenterVitepress.jl) - Vitepress backend for Documenter
- [Typst](https://typst.app/) - The Typst typesetting system

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

For detailed guidelines, see [CONTRIBUTING](docs/src/contributing.md).

### Development Quick Start

```bash
# Clone and setup
git clone https://github.com/lucifer1004/DocumenterTypst.jl
cd DocumenterTypst.jl
just dev

# Run tests
just test

# Format code with Runic
just format

# Build HTML docs
just docs

# Build Typst/PDF docs with different platforms
just docs-typst           # Use Typst_jll (default)
just docs-typst native    # Use system typst
just docs-typst none      # Generate .typ source only (no compilation)

# Run backend tests
just test-backend         # Use Typst_jll (default)
just test-backend native  # Use system typst
just test-backend none    # Generate .typ only (fastest)

# Generate changelog
just changelog
```

**Note**: This project uses [just](https://github.com/casey/just), a cross-platform command runner. Install it via:

- **macOS/Linux**: `brew install just` or `cargo install just`
- **Windows**: `cargo install just` or `scoop install just`

See the [just installation guide](https://github.com/casey/just#installation) for more options.

### Changelog Requirements

All user-visible changes **must** have a changelog entry in `CHANGELOG.md` under the "Unreleased" section.

For trivial changes (typo fixes, CI tweaks), add the "Skip Changelog" label to your PR.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on top of [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl)
- Powered by [Typst](https://typst.app/)
- LaTeX math rendering via [mitex](https://github.com/mitex-rs/mitex)
- Inspired by [DocumenterVitepress.jl](https://github.com/LuxDL/DocumenterVitepress.jl)
