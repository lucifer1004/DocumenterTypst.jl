# Link Edge Cases Test

This test suite validates PageLink handling for various edge cases.

## Test Scenarios

### 1. Links to pages with headings

Normal case - link without fragment to a page with headings:

- [Normal Page](normal.md) - should link to first heading
- [Nested Page](nested/deep.md) - should handle subdirectories
- [Multiple Headings Page](multiple.md) - should link to first heading

### 2. Links to pages without headings

Edge cases - link to pages that have no headings:

- [No Heading Page](no_heading.md) - should use page-level label
- [Empty Page](empty.md) - should use page-level label
- [Only Content Page](only_content.md) - should use page-level label

### 3. Links with fragments

Explicit fragment references:

- [Normal with Fragment](normal.md#Second-Section) - should work as before
- Note: Links to non-existent fragments would fail at compile time

### 4. Links in various contexts

Test links in different Markdown structures:

- **In lists**:
  1. [List Link to Normal](normal.md)
  2. [List Link to No Heading](no_heading.md)
- **In blockquotes**:

  > Reference: [Quote Link](normal.md)
  > Another: [Quote Link No Heading](no_heading.md)

- **In tables**:

| Link Type  | Example                                |
| ---------- | -------------------------------------- |
| Normal     | [Table Link](normal.md)                |
| No Heading | [Table Link No Heading](no_heading.md) |

### 5. Special characters in link text

- [Link with **bold**](normal.md)
- [Link with `code`](no_heading.md)
- [Link with _emphasis_](multiple.md)
- [Link with emoji 🔗](normal.md)

### 6. Multiple links to same target

First reference: [Normal Page](normal.md)  
Second reference: [Normal Page](normal.md)  
Third reference: [No Heading Page](no_heading.md)  
Fourth reference: [No Heading Page](no_heading.md)

### 7. Self-reference

Link to this page without fragment: [Index](index.md)

Link to this page with fragment: [Test Scenarios](#test-scenarios)
