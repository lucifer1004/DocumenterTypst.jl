# Typst Backend Integration Tests

This directory contains tests specifically for the Typst backend with different compilation platforms.

## Test Structure

- `runtests.jl` - Main test runner
- `src/` - Test documentation source files
- `builds/` - Generated output (git-ignored)

## Environment Variables

- `TYPST_PLATFORM` - Platform to test (`typst`, `native`, `docker`, `none`)

## Running Locally

```bash
# Test with Typst_jll (default)
julia --project=test/typst_backend test/typst_backend/runtests.jl

# Test with native typst
TYPST_PLATFORM=native julia --project=test/typst_backend test/typst_backend/runtests.jl

# Test source generation only
TYPST_PLATFORM=none julia --project=test/typst_backend test/typst_backend/runtests.jl
```

## Test Coverage

These tests verify:
- All platform options work correctly
- PDF generation succeeds (except `none`)
- `.typ` source files are valid
- Math rendering (LaTeX and Typst native)
- Cross-references and links
- Images and tables
- Multi-page documents

