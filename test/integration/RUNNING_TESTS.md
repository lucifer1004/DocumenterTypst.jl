# Running Integration Tests

## Quick Start

### Using just (Recommended)

```bash
# Default run (using Typst_jll)
just test-backend

# Specify platform
just test-backend typst    # Use Typst_jll (default)
just test-backend native   # Use system typst
just test-backend none     # Generate .typ source only
```

### Manual Run

#### Default run (using Typst_jll)

```bash
cd /Users/zihuaw/com.github/lucifer1004/DocumenterTypst
julia --project=test/typst_backend test/typst_backend/runtests.jl
```

### Testing Different Platforms

#### 1. Test with Typst_jll (default)

```bash
TYPST_PLATFORM=typst julia --project=test/typst_backend test/typst_backend/runtests.jl
```

#### 2. Test with system typst

```bash
# First ensure typst is installed
typst --version

# Run tests
TYPST_PLATFORM=native julia --project=test/typst_backend test/typst_backend/runtests.jl
```

#### 3. Test with source generation only (no compilation)

```bash
TYPST_PLATFORM=none julia --project=test/typst_backend test/typst_backend/runtests.jl
```

## Detailed Steps

### 1. First-time Setup

```bash
# Enter project directory
cd /Users/zihuaw/com.github/lucifer1004/DocumenterTypst

# Install test environment dependencies
julia --project=test/typst_backend -e '
  using Pkg
  Pkg.develop(PackageSpec(path=pwd()))
  Pkg.instantiate()'
```

### 2. Running Tests

#### Method 1: Direct run

```bash
julia --project=test/typst_backend test/typst_backend/runtests.jl
```

#### Method 2: Using Julia REPL

```julia
# Start Julia
julia --project=test/typst_backend

# In REPL
using Pkg
Pkg.develop(PackageSpec(path=pwd()))
Pkg.instantiate()

# Run tests
include("test/typst_backend/runtests.jl")
```

#### Method 3: Specify platform

```bash
# macOS/Linux
export TYPST_PLATFORM=native
julia --project=test/typst_backend test/typst_backend/runtests.jl

# Windows PowerShell
$env:TYPST_PLATFORM="native"
julia --project=test/typst_backend test/typst_backend/runtests.jl

# Windows CMD
set TYPST_PLATFORM=native
julia --project=test/typst_backend test/typst_backend/runtests.jl
```

## Test Coverage

Backend tests verify the following:

### ✅ Basic Document Generation

- Simple Markdown rendering
- Lists, bold, italic
- Code blocks
- `.typ` file generation
- PDF generation (non-`none` platforms)

### ✅ Math Rendering

- LaTeX math (via mitex)
- Native Typst math syntax
- Inline and display math

### ✅ Multi-page Documents

- Cross-page links
- Table of contents generation
- Cross-page references

### ✅ Tables and Special Characters

- Table rendering
- Special character escaping

## Viewing Test Output

Tests generate files in temporary directories, but you can preserve them:

```julia
# Modify runtests.jl or create your own test script
using Documenter
using DocumenterTypst

# Build in specified directory
makedocs(
    root = "/tmp/typst_test",
    source = "src",
    build = "build",
    sitename = "MyTest",
    format = DocumenterTypst.TypstWriter.Typst(platform = "none"),
    pages = ["index.md"],
    doctest = false,
    remotes = nothing,
)

# View generated files
# ls /tmp/typst_test/build/
```

## Debugging Failed Tests

### 1. View detailed output

```bash
julia --project=test/typst_backend test/typst_backend/runtests.jl -v
```

### 2. Enable Julia debug mode

```bash
JULIA_DEBUG=all julia --project=test/typst_backend test/typst_backend/runtests.jl
```

### 3. Run specific tests only

Edit `test/typst_backend/runtests.jl` and comment out unwanted `@testset`:

```julia
@testset "Typst Backend: $PLATFORM" begin
    @testset "Basic Document" begin
        # ... this will run
    end

    # @testset "Math Rendering" begin
    #     # ... this will be skipped
    # end
end
```

### 4. Save failed builds

```bash
# Set debug directory
export DOCUMENTER_TYPST_DEBUG="$HOME/typst-debug"
julia --project=test/typst_backend test/typst_backend/runtests.jl

# Check saved files
ls ~/typst-debug/
```

## Running in CI

In GitHub Actions CI, tests run like this:

```yaml
- name: Run Typst backend tests
  run: julia --project=test/typst_backend --code-coverage test/typst_backend/runtests.jl
  env:
    TYPST_PLATFORM: ${{ matrix.platform }}
```

## Common Issues

### Q: Tests say typst command not found (platform=native)

**A**: Need to install system typst:

```bash
# macOS
brew install typst

# Linux
curl -fsSL https://github.com/typst/typst/releases/latest/download/typst-x86_64-unknown-linux-musl.tar.xz | tar -xJ
sudo mv typst-*/typst /usr/local/bin/

# Verify installation
typst --version
```

### Q: Tests fail on Windows

**A**: Ensure:

1. Use correct path separators (handled automatically)
2. If testing `native` platform, need typst.exe in PATH
3. Consider testing only `typst` and `none` platforms

### Q: PDF generation fails but .typ file is fine

**A**:

1. Check if `.typ` file syntax is correct
2. Try manual compilation: `typst compile build/Test.typ`
3. View Typst compiler error messages

### Q: Tests are slow

**A**: Use `platform="none"` to skip PDF compilation:

```bash
TYPST_PLATFORM=none julia --project=test/typst_backend test/typst_backend/runtests.jl
```

## Adding New Backend Tests

Add new `@testset` in `test/typst_backend/runtests.jl`:

```julia
@testset "My New Feature" begin
    mktempdir() do dir
        srcdir = joinpath(dir, "src")
        mkpath(srcdir)

        write(joinpath(srcdir, "index.md"), """
        # My New Feature Test

        Test content here...
        """)

        makedocs(
            root = dir,
            source = "src",
            build = "build",
            sitename = "FeatureTest",
            format = DocumenterTypst.TypstWriter.Typst(platform = PLATFORM),
            pages = ["index.md"],
            doctest = false,
            remotes = nothing,
        )

        # Verify
        typfile = joinpath(dir, "build", "FeatureTest.typ")
        @test isfile(typfile)

        content = read(typfile, String)
        @test contains(content, "expected output")
    end
end
```

## Performance Benchmarks

Approximate run times on M4 Max:

- `platform="none"`: ~2-5 seconds (generate .typ only)
- `platform="typst"`: ~5-10 seconds (using Typst_jll)
- `platform="native"`: ~5-10 seconds (using system typst)

## Summary

Most commonly used commands:

```bash
# Using just (recommended)
just test-backend           # Use Typst_jll (default)
just test-backend native    # Use system typst
just test-backend none      # Generate .typ only (fastest, recommended for development)

# Manual run
# Quick test (recommended for development)
TYPST_PLATFORM=none julia --project=test/typst_backend test/typst_backend/runtests.jl

# Full test
julia --project=test/typst_backend test/typst_backend/runtests.jl

# Test system typst
TYPST_PLATFORM=native julia --project=test/typst_backend test/typst_backend/runtests.jl
```
