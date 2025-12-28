# Basic Usage

Simple examples to get you started.

## Minimal Example

Create `docs/make.jl`:

```julia
using Documenter
using DocumenterTypst
using MyPackage

makedocs(
    sitename = "MyPackage",
    authors = "Your Name",
    format = DocumenterTypst.Typst(),
    pages = ["index.md"]
)
```

Create `docs/src/index.md`:

`````markdown
# MyPackage

Welcome to the documentation!

## Installation

```julia
using Pkg
Pkg.add("MyPackage")
```
`````

`````

## Quick Start

````julia
using MyPackage

result = my_function(42)
```
`````

Build:

```bash
julia --project=docs docs/make.jl
```

Output: `docs/build/MyPackage.pdf`

## Multi-Page Documentation

```julia
makedocs(
    sitename = "MyPackage",
    format = DocumenterTypst.Typst(),
    pages = [
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "API" => "api.md",
    ]
)
```

## With Version Number

```julia
makedocs(
    sitename = "MyPackage",
    format = DocumenterTypst.Typst(version = "1.0.0"),
    pages = ["index.md"]
)
```

Output: `MyPackage-1.0.0.pdf`

## CI Integration

`.github/workflows/docs.yml`:

```yaml
name: Documentation

on:
  push:
    branches: [main]
    tags: ["*"]
  pull_request:

jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: julia-actions/setup-julia@v2
        with:
          version: "1.10"
      - uses: julia-actions/cache@v2
      - name: Install dependencies
        run: |
          julia --project=docs -e '
            using Pkg
            Pkg.develop(PackageSpec(path=pwd()))
            Pkg.instantiate()'
      - name: Build PDF
        run: julia --project=docs docs/make.jl
      - name: Upload PDF
        uses: actions/upload-artifact@v4
        with:
          name: documentation-pdf
          path: docs/build/*.pdf
```

## Complete Example

See the [Advanced Examples](advanced.md) page for more complex setups.
