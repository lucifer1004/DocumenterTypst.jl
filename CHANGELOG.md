# Release Notes

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## v0.1.0

### Added

- Automatic PDF optimization using pdfcpu_jll [#8]
- System font control via `use_system_fonts` option
  - Uses Typst's `--ignore-system-fonts` flag when disabled
- Detailed compilation timing for all stages [#8]
- Support for pure Typst files (`.typ`) as documentation sources alongside Markdown files [#8]
  - Automatic heading level adjustment using Typst's `offset` parameter
  - Resource paths preserved via `#include` directive
  - Mixed `.md` and `.typ` files in the same documentation project
- Documenter directives in Typst files via preprocessing [#8]
  - `// @typst-docs Module.function` - Include API documentation from docstrings
  - `// @typst-example ... // @typst-example-end` - Execute Julia code and display output
  - `// @typst-ref target` - Generate cross-reference links
  - Uses `Documenter.mdparse()` for consistent docstring rendering

### Changed

- **Documentation restructuring**: Improved organization and eliminated redundancy [#8]
  - Removed redundant files: `manual/pdf_optimization.md` (content merged into `configuration.md`), `examples/basic.md` (content merged into `getting_started.md`)
  - Streamlined `getting_started.md` from 270 lines to ~150 lines by moving advanced content to appropriate sections
  - Reorganized `math.md` to prioritize native Typst math over LaTeX (better UX for new users)
  - Simplified `index.md` and `README.md` to reduce duplication
  - Updated all internal links to reflect new structure
  - Unified all documentation to English (except example content demonstrating non-English features)
- Refactored `extended_heading` to use Typst state mechanism instead of parameter passing [#8]
  - Simplified function signature (removed `within-block` parameter)
  - Uses `in-container` state for tracking block context
  - Added `safe-block` wrapper for automatic state management
- BlockQuote rendering now uses `safe-block` instead of `quote` function for consistent heading behavior [#8]

### Removed

- **Docker backend (`platform="docker"`)**: Removed unused compilation backend [#8]
  - Docker platform was functionally redundant with Typst_jll (default)
  - Typst_jll provides better cross-platform support with zero setup
  - Users should migrate to `platform="typst"` (default) or `platform="native"`
  - Reduces maintenance burden and code complexity (41 lines removed)

### Fixed

- **CI linkcheck failure**: Skip `deploydocs()` when running linkcheck to avoid permission errors [#8]
  - linkcheck job only needs read permissions and shouldn't attempt deployment
- PDF file size bloat from uncompressed streams (100 MB → 15 MB for large documents after optimization) [#8]
- PDF size bloat from Type 3 emoji fonts (can be disabled via `use_system_fonts=false`) [#8]
- Compilation speed regression and outline number error caused by `colbreak` [#9]

## v0.0.x

### Added

- Typst backend for PDF generation with significantly faster compilation times (< 60s for large projects) compared to LaTeX. ([#5])
- Support for multiple compilation platforms:
  - `typst` (default): Uses Typst_jll for automatic cross-platform support
  - `native`: Uses system-installed Typst executable
  - `docker`: Docker-based compilation for reproducible builds
  - `none`: Generate `.typ` source only for custom pipelines
- LaTeX math support via [mitex](https://github.com/mitex-rs/mitex) for backward compatibility with existing Documenter documentation. ([#5])
- Native Typst math syntax support for new projects. ([#5])
- Full support for Documenter's Markdown AST including:
  - Code blocks with syntax highlighting
  - Tables with text wrapping
  - Images and figures
  - Cross-references and internal links
  - Admonitions (note, warning, danger, info, tip, compat)
  - Footnotes
  - Block quotes
  - Lists (ordered, unordered, nested)
- Custom template system via `docs/src/assets/custom.typ` for styling customization. ([#5])
  - Support for custom document content (title pages, prefaces, dedications)
  - Configuration option `skip-default-titlepage` to replace the default title page with custom content
  - Direct embedding of custom.typ content for proper variable scoping
- Comprehensive test suite with 128 tests covering:
  - Pure function unit tests
  - Configuration and compiler selection
  - AST rendering verification
  - Full document integration tests
- Professional default styling with configurable colors, fonts, and layout options. ([#5])
- Multi-page documentation support with automatic table of contents generation. ([#5])
- Complete user manual covering:
  - Getting started guide
  - Configuration options
  - Math support (LaTeX and Typst)
  - Custom styling (including custom title pages)
  - Troubleshooting
- Example tutorials:
  - Basic usage
  - Advanced features
  - Migration from LaTeX backend
- API reference documentation
- CI/CD setup guide
- Cross-platform development tooling with `justfile` supporting Windows, Linux, and macOS

<!-- Links generated by Changelog.jl -->

[#5]: https://github.com/lucifer1004/DocumenterTypst.jl/issues/5
[#8]: https://github.com/lucifer1004/DocumenterTypst.jl/issues/8
[#9]: https://github.com/lucifer1004/DocumenterTypst.jl/issues/9
