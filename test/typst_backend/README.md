# Typst Backend Integration Tests

This directory contains tests specifically for the Typst backend with different compilation platforms.

## Test Structure

- `runtests.jl` - Main test runner
- `src/` - Test documentation source files
- `builds/` - Generated output (git-ignored)

## Environment Variables

- `TYPST_PLATFORM` - Platform to test (`typst`, `native`, `none`)

## Running Locally

### Using just (recommended, cross-platform)

```bash
# Test with Typst_jll (default)
just test-backend

# Test with specific platform
just test-backend typst    # Typst_jll
just test-backend native   # System typst (requires typst installed)
just test-backend none     # Source generation only (fastest)
```

### Manual run

```bash
# Test with Typst_jll (default)
julia --project=test/typst_backend test/typst_backend/runtests.jl

# Test with specific platform (Unix/macOS/Linux)
TYPST_PLATFORM=native julia --project=test/typst_backend test/typst_backend/runtests.jl

# Test with specific platform (Windows PowerShell)
$env:TYPST_PLATFORM="native"
julia --project=test/typst_backend test/typst_backend/runtests.jl

# Cross-platform method
julia --project=test/typst_backend -e 'ENV["TYPST_PLATFORM"]="none"; include("test/typst_backend/runtests.jl")'
```

For detailed instructions, see [`RUNNING_TESTS.md`](RUNNING_TESTS.md).

## Test Coverage

These tests verify:

- All platform options work correctly
- PDF generation succeeds (except `none`)
- `.typ` source files are valid
- Math rendering (LaTeX and Typst native)
- Cross-references and links
- Images and tables
- Multi-page documents
