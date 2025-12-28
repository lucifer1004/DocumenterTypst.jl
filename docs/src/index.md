# DocumenterTypst.jl

_Fast, modern PDF generation for Julia documentation._

DocumenterTypst.jl is a [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) plugin that generates high-quality PDF documentation using the [Typst](https://typst.app/) typesetting system.

## Why DocumenterTypst?

### ⚡ Lightning Fast

- **< 90 seconds** to compile the full Julia documentation (vs several minutes with LaTeX)
- Powered by Typst's incremental compilation engine

### 🎨 Beautiful Output

- Modern, professional typography
- Consistent styling across all platforms
- High-quality PDF output optimized for both screen and print

### 🔧 Easy Setup

- No LaTeX distribution required
- Works out of the box with `Typst_jll.jl`
- Cross-platform support (Linux, macOS, Windows)

### 🧮 Flexible Math Support

- **LaTeX math** via [mitex](https://github.com/mitex-rs/mitex) for backward compatibility
- **Native Typst math** for new projects
- Seamless integration with existing Documenter documentation

### 🎯 Production Ready

- Built on stable Documenter internal APIs (same as DocumenterVitepress)
- Comprehensive test coverage (133+ tests)
- Active maintenance and community support

## Quick Example

```julia
using Documenter
using DocumenterTypst

makedocs(
    sitename = "MyPackage",
    authors = "Your Name",
    format = DocumenterTypst.Typst(),
    pages = [
        "Home" => "index.md",
        "API" => "api.md",
    ]
)
```

This generates a professional PDF with table of contents, cross-references, syntax highlighting, and more.

## Installation

```julia
using Pkg
Pkg.add("DocumenterTypst")
```

## Features at a Glance

| Feature           | Status |
| ----------------- | ------ |
| Fast Compilation  | ✅     |
| LaTeX Math        | ✅     |
| Typst Math        | ✅     |
| Code Blocks       | ✅     |
| Tables            | ✅     |
| Images            | ✅     |
| Cross-References  | ✅     |
| Admonitions       | ✅     |
| Footnotes         | ✅     |
| Table of Contents | ✅     |
| Custom Templates  | ✅     |
| Multi-page Docs   | ✅     |

## Comparison with LaTeX Backend

|                        | DocumenterTypst    | Documenter (LaTeX)          |
| ---------------------- | ------------------ | --------------------------- |
| **Compilation Time**   | < 90s (Julia docs) | Several minutes             |
| **Setup**              | Zero-config        | Requires LaTeX distribution |
| **File Size**          | Compact            | Compact                     |
| **Output Quality**     | High               | High                        |
| **Math Support**       | LaTeX + Typst      | LaTeX only                  |
| **Error Messages**     | Clear and helpful  | Sometimes cryptic           |
| **Incremental Builds** | ✅ Fast            | ❌ Slow                     |

## Next Steps

```@contents
Pages = [
    "manual/getting_started.md",
    "manual/configuration.md",
    "examples/basic.md",
]
Depth = 1
```

## Community

- **GitHub**: [lucifer1004/DocumenterTypst.jl](https://github.com/lucifer1004/DocumenterTypst.jl)
- **Issues**: Report bugs or request features
- **Discussions**: Share your experience and ask questions

## Acknowledgments

DocumenterTypst.jl builds upon:

- [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl) - The Julia documentation generator
- [Typst](https://typst.app/) - Modern typesetting system
- [mitex](https://github.com/mitex-rs/mitex) - LaTeX math in Typst
- [DocumenterVitepress.jl](https://github.com/LuxDL/DocumenterVitepress.jl) - Inspiration for the plugin architecture

## License

MIT License. See [LICENSE](https://github.com/lucifer1004/DocumenterTypst.jl/blob/main/LICENSE) for details.
