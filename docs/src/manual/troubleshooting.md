# Troubleshooting

Common issues and their solutions.

## Installation Issues

### Package Not Found

**Problem**: `ERROR: The following package names could not be resolved: DocumenterTypst`

**Solution**:

```julia
using Pkg
Pkg.Registry.update()
Pkg.add("DocumenterTypst")
```

### Dependency Conflicts

**Problem**: Version conflicts with Documenter

**Solution**:

```julia
# Update to latest compatible versions
Pkg.update(["Documenter", "DocumenterTypst"])

# Or specify versions explicitly
Pkg.add(name="Documenter", version="1.11")
Pkg.add("DocumenterTypst")
```

## Compilation Issues

### Typst Not Found

**Problem**: `ERROR: typst command not found`

**When**: Using `platform="native"`

**Solution**:

1. Use default `platform="typst"` (recommended)
2. Or install Typst:

   ```bash
   # macOS
   brew install typst

   # Linux
   cargo install --git https://github.com/typst/typst

   # Windows
   winget install Typst.Typst
   ```

### Compilation Timeout

**Problem**: Build hangs or takes too long

**Solutions**:

1. Check for infinite loops in custom templates
2. Use `platform="none"` to test without compilation
3. Enable verbose output:
   ```bash
   export DOCUMENTER_VERBOSE="true"
   julia docs/make.jl
   ```

## Content Issues

### Math Not Rendering

**Problem**: Math equations don't appear or look wrong

**Solutions**:

1. **Check syntax**:

   ````markdown
   # Correct (LaTeX)

   ```math
   \sum_{i=1}^n i
   ```

   # Correct (Typst)

   ```math typst
   sum_(i=1)^n i
   ```
   ````

2. **Escape backslashes**:

   ```markdown
   # Wrong

   `\alpha`

   # Correct

   `\\alpha`
   ```

3. **Use mitex-supported commands** - Some advanced LaTeX packages aren't supported

### Images Not Found

**Problem**: Images don't appear in PDF

**Solutions**:

1. **Use relative paths**:

   ```markdown
   # If in docs/src/manual/guide.md

   ![Caption](../assets/image.png) # ✅
   ![Caption](assets/image.png) # ❌
   ```

2. **Avoid absolute URLs** - Download images locally instead

3. **Check file exists**:
   ```bash
   ls docs/src/assets/image.png
   ```

### Code Blocks Wrong Language

**Problem**: Syntax highlighting incorrect

**Solution**: Specify language explicitly:

````markdown
```julia  # Not `jl`
function hello()
println("Hello!")
end

```

```
````

### Cross-References Broken

**Problem**: `@ref` links don't work

**Solutions**:

1. **Check anchor exists**:

   ```markdown
   ## My Section # Creates anchor "My-Section"

   See [My Section](@ref) # ✅
   See [My Section](#my-section) # ✅ (lowercase)
   ```

2. **Use exact heading text**:

   ```markdown
   ## Getting Started

   [Getting Started](@ref) # ✅
   [Get Started](@ref) # ❌
   ```

## Template Issues

### Custom Template Not Loading

**Problem**: Changes in `custom.typ` don't apply

**Solutions**:

1. **Check file location**:

   ```text
   docs/src/assets/custom.typ  # ✅
   docs/assets/custom.typ       # ❌
   ```

2. **Verify syntax**:

   ```typst
   #let config = (
     text-size: 12pt,  # ✅ Comma
   )
   ```

3. **Clear cache**:
   ```bash
   rm -rf docs/build
   julia docs/make.jl
   ```

### Fonts Not Found

**Problem**: Custom fonts don't work

**Solutions**:

1. **Check font name**:

   ```typst
   # Correct
   text-font: ("Inter", "DejaVu Sans")

   # Wrong (use exact name)
   text-font: ("inter", "dejavu")
   ```

2. **Install font** system-wide

3. **Use font path**:
   ```julia
   format = DocumenterTypst.Typst(
       platform = "native",
       typst = `typst --font-path /path/to/fonts`
   )
   ```

## CI/CD Issues

### GitHub Actions Failing

**Problem**: CI build fails

**Solutions**:

1. **Check Julia version**:

   ```yaml
   - uses: julia-actions/setup-julia@v2
     with:
       version: "1.10" # Minimum for DocumenterTypst
   ```

2. **Install dependencies**:

   ```yaml
   - name: Install dependencies
     run: |
       julia --project=docs -e '
         using Pkg
         Pkg.develop(PackageSpec(path=pwd()))
         Pkg.instantiate()'
   ```

3. **Add secrets**:
   - `DOCUMENTER_KEY`: For deployment
   - `GITHUB_TOKEN`: Automatic

### Deploy Failing

**Problem**: PDF not deployed to gh-pages

**Solution**: Use Documenter's deploy system:

```julia
using Documenter, DocumenterTypst

makedocs(format = DocumenterTypst.Typst(), ...)

deploydocs(
    repo = "github.com/user/Package.jl",
    devbranch = "main",
)
```

## Performance Issues

### Slow Builds

**Problem**: Compilation takes too long

**Solutions**:

1. **Use `platform="none"` for testing**:

   ```julia
   format = DocumenterTypst.Typst(platform = "none")
   ```

2. **Disable doctests during development**:

   ```julia
   makedocs(doctest = false, ...)
   ```

3. **Split large documents**

4. **Use incremental compilation** (Typst's default)

### Large PDF Files

**Problem**: PDF file too large

**Solutions**:

1. **Compress images** before including
2. **Use vector graphics** (SVG/PDF) instead of PNG
3. **Reduce image resolution** for screen viewing

## Debug Mode

### Enable Comprehensive Debugging

```bash
# Save generated .typ files
export DOCUMENTER_TYPST_DEBUG="debug-output"

# Verbose Documenter output
export DOCUMENTER_VERBOSE="true"

# Build
julia --project=docs docs/make.jl
```

### Inspect Generated Files

```bash
cd debug-output
ls -la  # See all generated files

# Compile manually to see errors
typst compile YourPackage.typ
```

## Getting Help

If you can't resolve an issue:

1. **Check existing issues**: [GitHub Issues](https://github.com/lucifer1004/DocumenterTypst.jl/issues)

2. **Create minimal example**:

   ```julia
   using Documenter, DocumenterTypst

   makedocs(
       sitename = "MWE",
       format = DocumenterTypst.Typst(),
       pages = ["index.md"],
   )
   ```

3. **Include debug output**:
   - Julia version: `versioninfo()`
   - DocumenterTypst version: `Pkg.status("DocumenterTypst")`
   - Error messages (full stack trace)
   - Generated .typ file (if relevant)

4. **Open an issue**: Provide all above information

## Known Limitations

### Not Yet Supported

- Live reload during development (use `platform="none"` + manual compile)
- Interactive elements (PDF format limitation)
- Animated GIFs (use static frames)
- Some advanced LaTeX packages in math

### Workarounds

For unsupported features, consider:

- Generate HTML docs for interactive content
- Use native Typst features instead of LaTeX
- Contribute a PR to add support!

## Version Compatibility

| DocumenterTypst | Documenter | Julia |
| --------------- | ---------- | ----- |
| 0.1.x           | 1.11+      | 1.10+ |

Always use compatible versions to avoid issues.
