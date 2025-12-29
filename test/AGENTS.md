# Testing Guide for AI Agents

## Quick Reference

### File Structure

```
test/
├── runtests.jl         # Main test suite (look here for examples)
├── test_helpers.jl     # render_to_typst(), extract_typst_body()
├── snapshot_helpers.jl # Snapshot testing utilities
├── snapshots/          # Saved snapshot files (.typ)
└── integration/        # Integration tests with actual compilation
    └── fixtures/       # Test fixtures (enhanced_typst, pure_typst, link_edge_cases)
```

### Where to Add Tests

- **Basic Markdown nodes** → `runtests.jl` PART 1: Core Tests → AST Rendering
- **Documenter features** (`@docs`, `@index`) → PART 2: Extended Coverage → Documenter Nodes
- **Edge cases** (Unicode, deep nesting) → PART 2: Extended Coverage → Edge Cases
- **Error handling** → PART 2: Extended Coverage → Error Detection
- **Regression prevention** → PART 3: Snapshot Tests (new features, complex structures)

### Two Testing Approaches

#### 1. Assertion-Based Tests (Traditional)

Use for focused, specific checks:

```julia
output = render_to_typst("**bold**")
@test contains(output, "#strong([bold])")
```

**Pros**: Fast, explicit expectations  
**Cons**: Only check what you assert, can miss unexpected changes

#### 2. Snapshot Tests (NEW)

Use for regression prevention:

```julia
test_snapshot("feature_name", "# Your markdown")
```

**Pros**: Captures full output, detects any change, human-readable diffs  
**Cons**: Needs manual approval for intentional changes

**When to use snapshots**:

- New Markdown node support
- Complex multi-node structures
- Known edge cases worth preserving
- Full document output validation

### Three-Layer Testing Pattern

Every significant feature needs three tests:

1. **Error Detection** - Use `@test_throws ErrorException` when input is invalid
2. **Graceful Degradation** - Use `makedocs(..., warnonly=true)` to verify recovery
3. **Happy Path** - Use `@test contains(output, expected)` for valid input

## Test Helpers

### Core Helpers (`test_helpers.jl`)

- `render_to_typst(markdown)` - Quick Markdown → Typst conversion (returns body only)
- `extract_typst_body(content)` - Strip preamble from .typ file

### Snapshot Helpers (`snapshot_helpers.jl`)

- `test_snapshot(name, markdown; update=false)` - Compare output against saved snapshot
- `should_update_snapshots()` - Check if `UPDATE_SNAPSHOTS=1` is set
- `normalize_snapshot_output(output)` - Remove dynamic content (timestamps, temp paths)
- `show_snapshot_diff(name, expected, actual)` - Display diff when snapshots don't match

## Running Tests

```bash
# Run all tests
julia --project=. -e 'using Pkg; Pkg.test()'

# Or using just
just test

# Update snapshot tests
UPDATE_SNAPSHOTS=1 julia --project=. test/runtests.jl

# Or using just
just test-snapshot-update
```

## Key Principles

1. **Test behavior, not implementation** - Focus on what code does, not how
2. **Failures should fail** - Use `@test_throws` to verify errors are caught
3. **One test, one behavior** - Keep tests focused
4. **platform="none"** for most tests - Skip compilation unless testing compiler

## Finding Examples

All patterns are in `runtests.jl`:

- Search for similar tests by node type or feature
- Copy pattern, adapt to your case
- Follow the three-layer structure for important features

## Common Patterns

**Simple node conversion:**

```julia
output = render_to_typst("# Your Markdown")
@test contains(output, "expected Typst")
```

**Full document build:**

```julia
mktempdir() do dir
    # setup src/index.md
    makedocs(...)
    content = read(joinpath(dir, "build", "Test.typ"), String)
    @test contains(content, "expected output")
end
```

**Error detection:**

```julia
@test_throws ErrorException makedocs(...)  # no warnonly
```

**Snapshot test:**

```julia
# First time: creates snapshot
UPDATE_SNAPSHOTS=1 julia test/runtests.jl

# After: verifies output matches snapshot
test_snapshot("my_feature", """
# Complex Structure

With **multiple** elements.
""")
```

See `runtests.jl` for complete examples.
