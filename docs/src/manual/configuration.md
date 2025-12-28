# Configuration

Detailed configuration options for DocumenterTypst.

## Typst Constructor

```julia
DocumenterTypst.Typst(;
    platform = "typst",
    version = "",
    typst = nothing,
)
```

### `platform::String`

Compilation backend. Options:

- **`"typst"`** (default): Uses `Typst_jll.jl`
  - Automatic installation
  - Cross-platform
  - Recommended for CI/CD

- **`"native"`**: Uses system `typst` executable
  - Requires manual installation
  - Can use custom path via `typst` parameter
  - Useful for development with latest Typst features

- **`"docker"`**: Docker-based compilation
  - Requires Docker
  - Reproducible builds
  - Isolated environment

- **`"none"`**: Generate `.typ` source only
  - No compilation
  - Fast for testing
  - Allows custom compilation pipeline

### `version::String`

Version string for the PDF filename.

```julia
# Output: MyPackage-1.2.3.pdf
format = DocumenterTypst.Typst(version = "1.2.3")
```

If unset, defaults to `ENV["TRAVIS_TAG"]` (deprecated) or empty string.

### `typst::Union{Cmd, String, Nothing}`

Custom path to `typst` executable. Only used with `platform="native"`.

```julia
# String path
format = DocumenterTypst.Typst(
    platform = "native",
    typst = "/opt/typst/bin/typst"
)

# Cmd object
format = DocumenterTypst.Typst(
    platform = "native",
    typst = `/usr/local/bin/typst --font-path /custom/fonts`
)
```

## makedocs Arguments

DocumenterTypst respects these `makedocs` arguments:

### `sitename::String`

Document title. Appears on title page and in metadata.

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

Document structure. Converted to table of contents.

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

Enable verbose output.

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

### Custom Title Pages

You can replace the default title page with your own:

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

**Note:** When `skip-default-titlepage: true`, you are responsible for creating your title page. The table of contents is still automatically generated.

See the [Custom Styling](styling.md) guide for more details and examples.

## Performance Tuning

### Faster Builds

```julia
makedocs(
    format = DocumenterTypst.Typst(platform = "none"),
    doctest = false,  # Skip doctests during development
)
```

### Parallel Builds

DocumenterTypst uses temporary directories, so you can run multiple builds in parallel:

```bash
julia --project=docs -e 'using YourPackage; include("docs/make.jl")' &
julia --project=docs -e 'using YourPackage; include("docs/make_alternate.jl")' &
wait
```

## CI/CD Configuration

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

### Platform-Specific Notes

**Linux**: Works out of the box with `Typst_jll`.

**macOS**: Works out of the box with `Typst_jll`.

**Windows**: Works out of the box with `Typst_jll`. Path handling is automatically normalized.

## Troubleshooting

See [Troubleshooting Guide](troubleshooting.md) for common issues and solutions.
