# Advanced Features

Advanced usage patterns and examples.

## Custom Templates

### Corporate Branding

Create `docs/src/assets/custom.typ`:

```typst
#let config = (
  // Company colors
  light-blue: rgb("0066cc"),
  dark-blue: rgb("003d7a"),

  // Company fonts
  text-font: ("Helvetica Neue", "Arial"),
  code-font: ("Consolas", "Courier New"),

  // Larger text for readability
  text-size: 12pt,
  code-size: 10pt,
)

// Company logo function
#let company-logo() = {
  image("logo.png", width: 3cm)
}
```

### Academic Style

```typst
#let config = (
  // Traditional academic styling
  text-font: ("Times New Roman", "Liberation Serif"),
  code-font: ("Courier New", "Liberation Mono"),

  // Conservative colors
  light-blue: rgb("000080"),
  dark-blue: rgb("000050"),

  // Larger line spacing
  text-size: 12pt,
)

// Citation helper
#let cite(key) = {
  text(fill: rgb("0000ff"))[[#key]]
}
```

## Multiple Output Formats

Generate both HTML and PDF:

```julia
# docs/make.jl
using Documenter, DocumenterTypst, MyPackage

# Build HTML documentation
makedocs(
    sitename = "MyPackage",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", "") == "true",
        canonical = "https://myorg.github.io/MyPackage.jl",
    ),
    pages = [
        "Home" => "index.md",
        "API" => "api.md",
    ]
)

deploydocs(
    repo = "github.com/myorg/MyPackage.jl",
    devbranch = "main",
)

# Build PDF documentation
makedocs(
    sitename = "MyPackage",
    format = DocumenterTypst.Typst(
        version = get(ENV, "GITHUB_REF_NAME", "dev"),
    ),
    pages = [
        "Home" => "index.md",
        "API" => "api.md",
    ]
)

# Upload PDF as artifact in CI
if get(ENV, "CI", "") == "true"
    cp("docs/build/MyPackage.pdf", "MyPackage-$(get(ENV, "GITHUB_REF_NAME", "dev")).pdf")
end
```

## Conditional Content

Show different content for PDF vs HTML:

```markdown
@raw html

<div class="only-html">
  <iframe src="https://example.com/interactive"></iframe>
</div>
```

````typst
@raw typst
#text(fill: red)[This appears only in PDF]
```
````

Or use metadata:

````markdown
```@meta
Format = Typst
```

This content only appears in PDF builds.

```

```
````

## Advanced Math

### Complex Equations

````markdown
```math
\begin{align}
  E &= mc^2 \\
  F &= ma \\
  \Delta S &\geq 0
\end{align}
```
````

### Custom Math Macros

In `custom.typ`:

```typst
// Define reusable math functions (Note: $ is Typst math delimiter)
#let bra(x) = [⟨#x|]
#let ket(x) = [|#x⟩]
#let braket(x, y) = [⟨#x|#y⟩]
```

## Performance Optimization

### Caching in CI

```yaml
# .github/workflows/docs.yml
- name: Cache Julia packages
  uses: actions/cache@v4
  with:
    path: |
      ~/.julia/packages
      ~/.julia/artifacts
    key: julia-pkgs-${{ runner.os }}-${{ hashFiles('docs/Project.toml') }}

- name: Cache Typst fonts
  uses: actions/cache@v4
  with:
    path: ~/.cache/typst
    key: typst-fonts-${{ runner.os }}
```

### Parallel Builds

Build multiple versions in parallel:

```yaml
strategy:
  matrix:
    version: ["stable", "dev", "v1.0.0"]
steps:
  - name: Build ${{ matrix.version }}
    run: |
      VERSION=${{ matrix.version }} julia docs/make.jl
      mv docs/build/Package.pdf Package-${{ matrix.version }}.pdf
```

## Integration with Other Tools

### Pre-commit Hook

`.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Build docs before committing

julia --project=docs -e '
  using Pkg
  Pkg.instantiate()
  include("docs/make.jl")
' || exit 1

echo "Documentation built successfully"
```

### Build Automation with Just

`justfile`:

```just
# Build both HTML and PDF documentation
docs: docs-html docs-pdf

# Build HTML documentation
docs-html:
    julia --project=docs -e 'using Pkg; Pkg.instantiate(); include("docs/make_html.jl")'

# Build PDF documentation
docs-pdf:
    julia --project=docs -e 'using Pkg; Pkg.instantiate(); include("docs/make_pdf.jl")'

# Clean build artifacts
clean:
    julia -e 'rm("docs/build", recursive=true, force=true)'
```

**Note**: [just](https://github.com/casey/just) is a cross-platform command runner that works on Windows, Linux, and macOS.

## Debugging

### Inspect Generated Typst

```julia
using DocumenterTypst

# Generate source only
makedocs(
    format = DocumenterTypst.Typst(platform = "none"),
    ...
)

# Manually compile with custom options
run(`typst compile docs/build/Package.typ --font-path /custom/fonts`)
```

### Profile Compilation

```julia
using Profile

@profiler makedocs(
    format = DocumenterTypst.Typst(),
    ...
)
```

## Migration Examples

### From LaTeX Backend

**Before** (`docs/make.jl`):

```julia
using Documenter, MyPackage

makedocs(
    format = Documenter.LaTeX(),
    ...
)
```

**After**:

```julia
using Documenter, DocumenterTypst, MyPackage

makedocs(
    format = DocumenterTypst.Typst(),
    ...
)
```

No changes needed to markdown files!

### From Manual PDF Generation

**Before**: Complex LaTeX setup with custom templates

**After**: Simple Typst configuration

```julia
makedocs(
    format = DocumenterTypst.Typst(),
    ...
)
```

Add `docs/src/assets/custom.typ` for styling.

## Real-World Examples

See these projects using DocumenterTypst:

- [Example1.jl](https://github.com/user/Example1.jl) - Basic usage
- [Example2.jl](https://github.com/user/Example2.jl) - Custom styling
- [Example3.jl](https://github.com/user/Example3.jl) - Multiple formats

## Best Practices

1. **Version Control** - Track `custom.typ` in git
2. **Test Locally** - Build before pushing
3. **Use Caching** - Speed up CI builds
4. **Pin Versions** - Specify Documenter version in compat
5. **Document Changes** - Keep CHANGELOG.md updated

## Tips & Tricks

### Quick Preview

```bash
# Fast iteration during development
julia --project=docs -e '
  using DocumenterTypst
  makedocs(
    format = DocumenterTypst.Typst(platform = "none"),
    doctest = false,
  )
'
cd docs/build && typst watch Package.typ
```

### Conditional Debugging

```julia
debug_mode = get(ENV, "DEBUG", "false") == "true"

makedocs(
    format = DocumenterTypst.Typst(
        platform = debug_mode ? "none" : "typst"
    ),
    ...
)

if debug_mode
    ENV["DOCUMENTER_TYPST_DEBUG"] = "debug"
end
```

### Custom PDF Name

```julia
# Generate with custom name
makedocs(format = DocumenterTypst.Typst(), ...)
cp("docs/build/Package.pdf", "custom-name.pdf")
```
