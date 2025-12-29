# Testing Guide for AI Agents

## Quick Reference

### File Structure

```
test/
├── runtests.jl       # Main test suite (look here for examples)
├── test_helpers.jl   # render_to_typst(), extract_typst_body()
└── typst_backend/    # Integration tests with actual compilation
```

### Where to Add Tests

- **Basic Markdown nodes** → `runtests.jl` PART 1: Core Tests → AST Rendering
- **Documenter features** (`@docs`, `@index`) → PART 2: Extended Coverage → Documenter Nodes
- **Edge cases** (Unicode, deep nesting) → PART 2: Extended Coverage → Edge Cases
- **Error handling** → PART 2: Extended Coverage → Error Detection

### Three-Layer Testing Pattern

Every significant feature needs three tests:

1. **Error Detection** - Use `@test_throws ErrorException` when input is invalid
2. **Graceful Degradation** - Use `makedocs(..., warnonly=true)` to verify recovery
3. **Happy Path** - Use `@test contains(output, expected)` for valid input

## Test Helpers

- `render_to_typst(markdown)` - Quick Markdown → Typst conversion (returns body only)
- `extract_typst_body(content)` - Strip preamble from .typ file

Both defined in `test_helpers.jl`.

## Running Tests

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
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

See `runtests.jl` for complete examples.
