# Integration Tests

This directory contains integration tests for DocumenterTypst with different compilation platforms.

## Test Structure

- `runtests.jl` - Main test runner
- `fixtures/` - Test fixtures for various scenarios:
  - `enhanced_typst/` - Tests for enhanced Typst features
  - `pure_typst/` - Tests for pure Typst file inclusion
  - `link_edge_cases/` - Tests for PageLink handling edge cases
- `builds/` - Generated output (git-ignored)

## Environment Variables

- `TYPST_PLATFORM` - Platform to test (`typst`, `native`, `none`)

## Running Locally

### Using just (recommended, cross-platform)

```bash
# Test with Typst_jll (default)
just test-integration

# Test with specific platform
just test-integration typst    # Typst_jll
just test-integration native   # System typst (requires typst installed)
just test-integration none     # Source generation only (fastest)
```

### Manual run

```bash
# Test with Typst_jll (default)
julia --project=test/integration test/integration/runtests.jl

# Test with specific platform (Unix/macOS/Linux)
TYPST_PLATFORM=native julia --project=test/integration test/integration/runtests.jl

# Test with specific platform (Windows PowerShell)
$env:TYPST_PLATFORM="native"
julia --project=test/integration test/integration/runtests.jl

# Cross-platform method
julia --project=test/integration -e 'ENV["TYPST_PLATFORM"]="none"; include("test/integration/runtests.jl")'
```

For detailed instructions, see [`RUNNING_TESTS.md`](RUNNING_TESTS.md).

## Test Coverage

### Fixtures

#### enhanced_typst

- Tests enhanced Typst features with Documenter integration
- Validates custom Typst content embedding

#### pure_typst  

- Tests pure `.typ` file inclusion
- Verifies nested directory structures
- Tests image assets handling

#### link_edge_cases (NEW)

- Tests PageLink without fragment to pages with headings
- Tests PageLink to pages without any headings
- Tests page-level label generation
- Validates links in various contexts (lists, tables, blockquotes)
- Tests multiple links to same target
- Tests self-references and bidirectional links

### Coverage Areas

These tests verify:

- All platform options work correctly (`typst`, `native`, `none`)
- PDF generation succeeds (except `none` platform)
- `.typ` source files are valid Typst code
- Math rendering (LaTeX and Typst native)
- Cross-references and internal links
- Images and tables
- Multi-page documents
- PageLink edge cases and fallback behaviors
