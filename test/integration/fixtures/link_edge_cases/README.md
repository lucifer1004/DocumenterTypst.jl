# Link Edge Cases - Integration Test Fixture

This fixture validates PageLink handling for edge cases, testing the behavior when links
don't have explicit fragments.

## What It Tests

### 1. Links to pages WITH headings

Pages that have headings should link to the first heading automatically.

**Example**: `[Normal Page](normal.md)` → links to `#Normal-Page` label

### 2. Links to pages WITHOUT headings  

Pages without any headings should get a page-level label and links should work.

**Example**: `[No Heading](no_heading.md)` → links to `no_heading.md#page` label

### 3. Backward compatibility

Explicit fragment references should continue to work as before.

**Example**: `[Section](normal.md#Second-Section)` → links to specific section

## Test Files

| File | Purpose |
|------|---------|
| `index.md` | Main test page with all link scenarios |
| `normal.md` | Page with multiple headings (normal case) |
| `multiple.md` | Page with 5 headings |
| `no_heading.md` | Page without headings (rich content) |
| `empty.md` | Minimal content page without headings |
| `only_content.md` | Only non-heading content |
| `nested/deep.md` | Page in subdirectory |

## Integration

This fixture is automatically run as part of the integration test suite via
`test/integration/runtests.jl`. It tests:

- Page-level label generation for heading-less pages
- Links to first heading for pages with headings
- Links to page labels for heading-less pages
- Multiple link contexts (lists, tables, blockquotes)
- Nested directories
- Bidirectional links

## Running Standalone

```bash
cd test/integration/fixtures/link_edge_cases
julia --project=../../../.. make.jl
```

Or as part of full integration suite:

```bash
just test-integration
```

## Expected Output

### For pages WITH headings (normal.md)

```typst
#heading(level: 2, [Normal Page])
 #label("normal.md#Normal-Page")
```

### For pages WITHOUT headings (no_heading.md)

```typst
[] #label("no_heading.md#page")

This page has no headings...
```

### Links to them

```typst
#link(label("normal.md#Normal-Page"))[Normal Page]
#link(label("no_heading.md#page"))[No Heading Page]
```
