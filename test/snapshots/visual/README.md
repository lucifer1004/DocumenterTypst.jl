# Visual Regression Tests

Visual snapshots for layout-dependent template features that cannot be verified by text comparison.

## What Are Visual Snapshots?

Visual snapshots test the **rendered appearance** of PDF pages by:

1. Compiling Typst code (or existing .typ files) to PNG images
2. Computing SHA256 hash of each PNG
3. Comparing against saved hashes
4. Flagging any visual changes

## Two Testing Approaches

### 1. Integration Fixture Testing (Recommended)

Test complete documentation projects from `test/integration/fixtures/`:

```julia
# Build fixture and test its output
test_visual_from_file("fixture_name", "path/to/build/output.typ"; pages=[1,2,3])
```

**Use for:**

- Multi-page documents with headers/footers
- Table of contents rendering
- Part and Chapter page layouts
- Complete real-world documentation

### 2. Inline Code Testing

Test specific template configurations:

```julia
test_visual("feature_name", """
#import "documenter.typ": *
#show: documenter.with(config: (...))
...
"""; pages=[2,3])
```

**Use for:**

- Testing specific config options
- Isolated template features
- Custom configuration validation

## Why Visual Testing?

Text snapshots (`test/snapshots/*.typ`) verify **code generation**.  
Visual snapshots verify **layout and appearance**:

- ✅ Header/footer positioning across multiple pages
- ✅ Table of contents layout and page numbers
- ✅ Page breaks and multi-page behavior
- ✅ Part/Chapter page styling
- ✅ Complete document flow (title → TOC → chapters)
- ✅ Configuration effects on appearance

**Key insight:** Headers, footers, and outlines only make sense in multi-page documents.
That's why we primarily test integration fixtures, not simple inline examples.

## Directory Structure

```
test/snapshots/visual/
├── README.md                    # This file
├── *_page*.hash                 # Hash snapshots (committed to git)
├── references/                  # Reference PNG images (committed for docs)
│   ├── header_chapter_page2.png
│   └── ...
└── failures/                    # Failed test PNGs (git-ignored, auto-cleaned)
    ├── test_name_page1_actual.png
    └── ...
```

## File Types

### `.hash` files (Required)

- SHA256 hashes of PNG images
- Small (64 bytes per page)
- **Must be committed** to git
- Used for automated comparison

### `references/` PNGs (Optional)

- Human-readable reference images
- Generated when updating snapshots
- **Can be committed** for documentation
- Help reviewers see what changed

### `failures/` PNGs (Temporary)

- Generated when tests fail
- Show actual output for debugging
- **Git-ignored**, cleaned before each test run
- Useful for local debugging

## Usage

### Running Visual Tests

```bash
# Run all tests (including visual)
just test

# Or directly
julia --project=. test/runtests.jl
```

Visual tests are skipped if:

- `TYPST_PLATFORM=none` (no compiler available)
- `typst` command not found

### Updating Snapshots

When you intentionally change visual output:

```bash
# Update all snapshots (text + visual)
UPDATE_SNAPSHOTS=1 julia --project=. test/runtests.jl

# Or using just
just test-snapshot-update
```

This will:

1. Generate new PNG images
2. Compute new hashes
3. Save hashes to `.hash` files
4. Save reference PNGs to `references/`

### Debugging Failures

When a visual test fails:

1. **Check terminal output** - shows expected vs actual hash
2. **Inspect failure PNG** - saved to `failures/test_name_pageN_actual.png`
3. **Compare with reference** - check `references/test_name_pageN.png`
4. **Decide**: Bug in code? Update snapshot? Expected change?

```bash
# View failed output
open test/snapshots/visual/failures/header_chapter_page2_actual.png

# Compare with reference
open test/snapshots/visual/references/header_chapter_page2.png
```

## Adding New Visual Tests

### For Integration Fixtures

1. Add to `test/runtests.jl` → PART 4: Visual Regression Tests:

```julia
@testset "My Fixture" begin
    fixture_dir = joinpath(fixtures_dir, "my_fixture")
    
    # Build the fixture
    run(`julia --project=$fixture_dir $(joinpath(fixture_dir, "make.jl"))`)
    
    # Test key pages
    typ_path = joinpath(fixture_dir, "build", "output.typ")
    test_visual_from_file("my_fixture", typ_path; update, pages=[1,2,3,4])
end
```

### For Configuration Options

```julia
test_visual("config_option", """
#import "documenter.typ": *
#show: documenter.with(
  title: "Test",
  config: (option: value)
)
= Content
"""; update, pages=[2,3])
```

Then generate initial snapshot:

```bash
UPDATE_SNAPSHOTS=1 julia --project=. test/runtests.jl
```

## What to Test Visually

### ✅ Good Candidates

- **Integration fixtures** - Complete multi-page documents
- Header/footer content and positioning (requires multiple pages)
- Table of contents layout (requires multiple chapters)
- Part and Chapter pages (requires document structure)
- Page breaks and continuations
- Configuration options that affect multi-page layout
- Document flow (title → TOC → content)

### ❌ Bad Candidates

- Single-page simple examples (no headers/footers to test)
- Text content (use text snapshots instead)
- Simple inline formatting (already covered by text snapshots)
- Features that don't require compilation (labels, metadata)

## CI/CD Workflow

### In CI

```yaml
# Visual tests run automatically
- run: julia --project=. test/runtests.jl
  # Fails if hashes don't match
  # No PNG generation needed (just hash comparison)
```

### In PRs

1. Visual tests run and compare hashes
2. If changed, reviewer checks:
   - `git diff test/snapshots/visual/*.hash`
   - New PNG in `references/` (if committed)
3. Approve or request changes

### Updating in CI

Visual snapshots should **only** be updated:

- When template changes are intentional
- After manual review of visual diff
- Never automatically in CI

## Performance

- **Hash comparison**: Fast (~1ms per page)
- **PNG generation**: Moderate (~100-500ms per page)
- **Update mode**: Slower (generates + saves PNGs)
- **Verify mode**: Fast (only compares hashes)

Typical test run:

- 10 visual tests × 2 pages = 20 comparisons
- Total time: ~5-10 seconds

## Troubleshooting

### Test fails with "No typst compiler"

```bash
# Check if typst is available
which typst

# Or skip visual tests
TYPST_PLATFORM=none julia test/runtests.jl
```

### Hash mismatch after no changes

- Font rendering might differ across systems
- Typst version differences
- Solution: Regenerate snapshots on target platform

### PNG not generated

- Check Typst compilation errors
- Verify `documenter.typ` is accessible
- Try manual compilation:

  ```bash
  typst compile test.typ --format png --ppi 150 output.png
  ```

## Best Practices

1. **Test specific features** - One visual test per layout concern
2. **Use minimal content** - Just enough to show the feature
3. **Test critical pages** - Usually page 2-3 (after title/TOC)
4. **Commit reference PNGs** - Helps code review
5. **Clean failures** - Auto-cleaned, but can manually `rm -rf test/snapshots/visual/failures/`
6. **Review changes carefully** - Visual regressions are subtle

## Implementation Details

- **Hash algorithm**: SHA256 (crypto-grade, zero collision risk)
- **PNG resolution**: 150 PPI (good quality, reasonable file size)
- **Page selection**: Configurable per test
- **Typst flags**: `--format png --ppi 150`
- **Dependencies**: None (uses Julia stdlib `SHA`)

## Examples

### Integration Fixture Test

```julia
# Test complete documentation project
fixture_dir = joinpath(fixtures_dir, "enhanced_typst")
run(`julia --project=$fixture_dir $(joinpath(fixture_dir, "make.jl"))`)

typ_path = joinpath(fixture_dir, "build", "output.typ")
test_visual_from_file("enhanced_typst", typ_path; pages=[1, 2, 3, 4])
# Pages: title, TOC, first chapter, continuation (with header)
```

### Configuration Test

```julia
# Test specific config option
test_visual("config_no_header", """
#import "documenter.typ": *
#show: documenter.with(
  title: "Test",
  config: (header-mode: "none")
)
= Part 1
== Chapter 1
Content
#pagebreak()
More content - no header should appear
"""; pages=[2, 3, 4])
```

See `test/runtests.jl` for complete examples.
