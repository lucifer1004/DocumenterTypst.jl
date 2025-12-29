# Configuration

Complete configuration reference for DocumenterTypst.

## Constructor

```julia
DocumenterTypst.Typst(;
    platform = "typst",
    version = "",
    typst = nothing,
    optimize_pdf = true,
    use_system_fonts = true,
    font_paths = String[],
)
```

## Parameters

### `platform::String`

Compilation backend. **Default: `"typst"`**

| Value      | Description                       | Use Case           |
| ---------- | --------------------------------- | ------------------ |
| `"typst"`  | Uses `Typst_jll.jl` (recommended) | Production, CI/CD  |
| `"native"` | Uses system `typst` executable    | Development        |
| `"none"`   | Generate `.typ` source only       | Testing, debugging |

**Examples**:

```julia
# Default (recommended)
format = DocumenterTypst.Typst()

# Use system typst
format = DocumenterTypst.Typst(platform = "native")

# Generate source only (fast for development)
format = DocumenterTypst.Typst(platform = "none")
```

**Installing native Typst**:

```bash
# macOS
brew install typst

# Linux (via cargo)
cargo install --git https://github.com/typst/typst

# Windows
winget install --id Typst.Typst
```

### `version::String`

Version string for PDF filename. **Default: `""`**

```julia
format = DocumenterTypst.Typst(version = "1.2.3")
# Output: MyPackage-1.2.3.pdf
```

If unset, no version suffix is added.

### `typst::Union{Cmd, String, Nothing}`

Custom path to `typst` executable. **Default: `nothing`**

Only used with `platform="native"`.

```julia
# String path
format = DocumenterTypst.Typst(
    platform = "native",
    typst = "/opt/typst/bin/typst"
)

# Cmd object (with custom flags)
format = DocumenterTypst.Typst(
    platform = "native",
    typst = `/usr/local/bin/typst --font-path /custom/fonts`
)
```

### `optimize_pdf::Bool`

Enable automatic PDF optimization. **Default: `true`**

When enabled, DocumenterTypst uses `pdfcpu` to compress the generated PDF:

- Compresses uncompressed content streams
- Optimizes PDF object structure
- **Typically reduces file size by 60-85%** for large documents
- Adds ~2 seconds to build time

```julia
# Enable optimization (recommended for production)
format = DocumenterTypst.Typst(optimize_pdf = true)

# Disable optimization (faster builds for development)
format = DocumenterTypst.Typst(optimize_pdf = false)
```

**Output**:

```text
Info: TypstWriter: optimizing PDF with pdfcpu...
└   size_before = "42.79 MB"

Info: TypstWriter: PDF optimization completed.
│   size_after = "15.23 MB"
│   reduction = "64.4%"
└   time = "1.85s"
```

### `use_system_fonts::Bool`

Control whether Typst can use system-installed fonts. **Default: `true`**

When set to `false`, uses Typst's `--ignore-system-fonts` flag:

- Prevents Type 3 emoji fonts (e.g., AppleColorEmoji) from being embedded
- **Can reduce PDF size by 40+ MB** for emoji-heavy documents
- Only fonts explicitly specified in the template will be used

```julia
# Use system fonts (default, maximum compatibility)
format = DocumenterTypst.Typst(use_system_fonts = true)

# Ignore system fonts (recommended for production)
format = DocumenterTypst.Typst(use_system_fonts = false)
```

**Performance comparison** (Julia documentation, 2211 pages):

| Configuration        | PDF Size |
| -------------------- | -------- |
| With system fonts    | 100 MB   |
| Without system fonts | 60 MB    |
| + optimization       | 15 MB    |

### `font_paths::Vector{String}`

Additional font directories for Typst. **Default: `String[]`**

```julia
format = DocumenterTypst.Typst(
    font_paths = ["/path/to/fonts", "/another/path"]
)
```

Fonts in these directories will be available for use in custom templates.

## Documenter Integration

DocumenterTypst respects these `makedocs` arguments:

### `sitename::String`

Document title. Appears on title page and in PDF metadata.

```julia
makedocs(
    sitename = "MyPackage Documentation",
    format = DocumenterTypst.Typst(),
)
```

### `authors::String`

Author names. Appears on title page.

```julia
makedocs(
    authors = "John Doe, Jane Smith",
    format = DocumenterTypst.Typst(),
)
```

### `pages::Vector`

Document structure. Converted to table of contents and sections.

```julia
makedocs(
    pages = [
        "Home" => "index.md",
        "Manual" => [
            "Getting Started" => "manual/start.md",
            "Advanced" => "manual/advanced.md",
        ],
        "API" => "api.md",
    ],
    format = DocumenterTypst.Typst(),
)
```

## Production Configuration

### Recommended Settings

For **minimal PDF size** and **optimal quality**:

```julia
makedocs(
    format = DocumenterTypst.Typst(
        platform = "typst",           # Use Typst_jll (default)
        optimize_pdf = true,          # Enable optimization (default)
        use_system_fonts = false,     # Minimize size (NOT default)
    ),
)
```

This configuration produces PDFs that are:

- 85% smaller than unoptimized builds
- 40-60 MB smaller than builds with system fonts
- Comparable in size to LaTeX output

### Development Configuration

For **fast iteration** during development:

```julia
makedocs(
    format = DocumenterTypst.Typst(
        platform = "none",            # Skip PDF generation
        optimize_pdf = false,         # Skip optimization
    ),
    doctest = false,                  # Skip doctests
)
```

This only generates the `.typ` source file (~1 second for large projects).

## Environment Variables

### `DOCUMENTER_TYPST_DEBUG`

Save generated `.typ` files for debugging.

```bash
# Save to default temp directory
export DOCUMENTER_TYPST_DEBUG=""

# Save to specific directory
export DOCUMENTER_TYPST_DEBUG="typst-debug"

julia docs/make.jl
```

Output location will be printed:

```text
┌ Info: Typst sources copied for debugging to /path/to/typst-debug
```

### `DOCUMENTER_VERBOSE`

Enable verbose output from Documenter.

```bash
export DOCUMENTER_VERBOSE="true"
julia docs/make.jl
```

## Custom Templates

Override default styling by creating `docs/src/assets/custom.typ`:

```typst
// docs/src/assets/custom.typ

// Custom colors and fonts
#let config = (
  light-blue: rgb("3498db"),
  dark-blue: rgb("2c3e50"),

  // Custom font sizes
  text-size: 12pt,
  code-size: 10pt,

  // Custom fonts
  text-font: ("Times New Roman", "DejaVu Serif"),
  code-font: ("Fira Code", "DejaVu Sans Mono"),
)
```

The content of this file is automatically embedded in the generated document.

See [Custom Styling](styling.md) for detailed examples.

### Custom Title Pages

Replace the default title page:

```typst
// docs/src/assets/custom.typ

#let config = (
  skip-default-titlepage: true,  // Skip the default title page
  // ... other config options
)

// Your custom title page
#page(
  margin: (left: 2cm, right: 2cm, bottom: 3cm, top: 2cm),
  header: none,
  footer: none,
  numbering: none,
)[
  #align(center)[
    #v(3cm)
    #image("logo.png", width: 150pt)
    #v(2cm)
    #text(size: 48pt, weight: "bold")[My Package]
    #v(1cm)
    #text(size: 24pt)[Documentation]
    #v(1fr)
    #text(size: 14pt, fill: gray)[Version 1.0 • December 2025]
  ]
]

#pagebreak()
```

## Performance Tuning

### Build Timing

DocumenterTypst reports detailed timing for each build stage:

```text
Info: TypstWriter: AST conversion completed.
└   time = "0.45s"

Info: TypstWriter: Typst compilation completed.
└   time = "0.33s"

Info: TypstWriter: PDF optimization completed.
│   size_after = "0.04 MB"
│   reduction = "34.9%"
└   time = "0.05s"
```

Total build time is typically **under 10 seconds** for medium-sized documentation.

### Parallel Builds

DocumenterTypst uses temporary directories, so you can run multiple builds in parallel:

```bash
julia --project=docs -e 'include("docs/make.jl")' &
julia --project=docs -e 'include("docs/make_alternate.jl")' &
wait
```

## CI/CD Integration

### GitHub Actions

```yaml
- name: Build PDF documentation
  run: |
    julia --project=docs -e '
      using Pkg
      Pkg.develop(PackageSpec(path=pwd()))
      Pkg.instantiate()
      include("docs/make.jl")
    '
  env:
    DOCUMENTER_KEY: ${{ secrets.DOCUMENTER_KEY }}
```

### Platform Support

**Linux**: Works out of the box with `Typst_jll`.

**macOS**: Works out of the box with `Typst_jll`.

**Windows**: Works out of the box with `Typst_jll`. Path handling is automatically normalized.

## Advanced Usage

### Pure Typst Files

Include existing `.typ` files directly alongside Markdown files:

```julia
makedocs(
    pages = [
        "Home" => "index.md",           # Markdown (converted)
        "Manual" => "manual.typ",       # Pure Typst (included as-is)
        "API" => [
            "Overview" => "api/index.md",
            "Reference" => "api/ref.typ",
        ],
    ]
)
```

**How it works**:

- **Heading levels**: Automatically adjusted using Typst's `offset` parameter
- **Resource paths**: Preserved via `#include`
- **Page breaks**: Level 1-2 headings get automatic page breaks

**Limitations**:

- Content is **only included in Typst/PDF output**, not HTML
- Documenter's cross-reference system doesn't index `.typ` content

### Documenter Directives in Typst Files

!!! tip "New in v0.2.0"
    You can now use Documenter-style directives within `.typ` files!

While `.typ` files are not processed through Documenter's full pipeline, you can use special preprocessing directives to access Documenter features:

#### `@typst-docs` - Include API Documentation

```typst
= API Reference

// @typst-docs MyModule.function_name
// @typst-docs MyModule.AnotherType
```

This will expand to the full docstring documentation, similar to `@docs` blocks in Markdown files.

**Example output**:

```typst
#raw("MyModule.function_name") #label(...) -- Function.
#extended_grid(columns: (2em, 1fr), [], [
  // Formatted docstring content with code blocks, lists, etc.
])
```

#### `@typst-example` - Execute and Display Code

```typst
= Examples

// @typst-example
// x = 1 + 1
// println("Result: $x")
// @typst-example-end
```

This executes the Julia code and displays both the code and its output, similar to `@example` blocks in Markdown.

**Generated output**:

```typst
#raw("x = 1 + 1\nprintln(\"Result: \$x\")", block: true, lang: "julia")
#raw("Result: 2", block: true, lang: "text")
```

#### `@typst-ref` - Cross-Reference Links

```typst
See also: // @typst-ref MyModule.related_function
```

This generates a clickable cross-reference link, similar to `@ref` in Markdown.

**Generated output**:

```typst
See also: #link(label("file.typ#MyModule.related_function"))[MyModule.related_function]
```

#### How It Works

1. **Preprocessing**: When a `.typ` file is included, DocumenterTypst scans for these special comments
2. **Expansion**: Each directive is expanded into native Typst code

**Limitations**:

- Directives must be in comments starting with `//`
- `@typst-example` code runs in the module's namespace (use fully qualified names if needed)
- Cross-references only work within the Typst/PDF output

See [Getting Started](getting_started.md) for a complete example.

## Troubleshooting

See [Troubleshooting Guide](troubleshooting.md) for common issues and solutions.
