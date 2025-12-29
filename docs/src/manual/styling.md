# Custom Styling

Customize the appearance of your PDF documentation.

## Overview

DocumenterTypst uses a default template (`documenter.typ`) that provides professional styling out of the box. You can customize it by creating your own `custom.typ` file.

## Quick Start

Create `docs/src/assets/custom.typ`:

```typst
// Override default configuration
#let config = (
  // Your customizations here
  light-blue: rgb("3498db"),
  text-size: 12pt,
)
```

This file is automatically loaded if it exists.

## Available Options

### Colors

```typst
#let config = (
  // Primary colors
  light-blue: rgb("6b85dd"),
  dark-blue: rgb("4266d5"),
  light-red: rgb("d66661"),
  dark-red: rgb("c93d39"),
  light-green: rgb("6bab5b"),
  dark-green: rgb("3b972e"),
  light-purple: rgb("aa7dc0"),
  dark-purple: rgb("945bb0"),

  // UI colors
  codeblock-background: rgb("f6f6f6"),
  codeblock-border: rgb("e6e6e6"),

  // Admonition colors
  admonition-colors: (
    default: rgb("363636"),
    danger: rgb("da0b00"),
    warning: rgb("ffdd57"),
    note: rgb("209cee"),
    info: rgb("209cee"),
    tip: rgb("22c35b"),
    compat: rgb("1db5c9"),
  ),
)
```

### Typography

```typst
#let config = (
  // Font sizes
  text-size: 11pt,
  code-size: 9pt,
  heading-size-title: 24pt,
  heading-size-part: 18pt,
  heading-size-chapter: 18pt,
  heading-size-section: 14pt,
  heading-size-subsection: 13pt,
  heading-size-subsubsection: 12pt,

  // Font families
  text-font: ("Inter", "DejaVu Sans"),
  code-font: ("JetBrains Mono", "DejaVu Sans Mono"),
)
```

### Layout

```typst
#let config = (
  // Table styling
  table-stroke-width: 0.5pt,
  table-stroke-color: rgb("cccccc"),
  table-inset: 8pt,

  // Quote styling
  quote-background: rgb("f8f8f8"),
  quote-border-color: rgb("cccccc"),
  quote-border-width: 4pt,
  quote-inset: (left: 15pt, right: 15pt, top: 10pt, bottom: 10pt),

  // Admonition styling
  admonition-title-inset: (left: 1em, right: 5pt, top: 5pt, bottom: 5pt),
  admonition-content-inset: 10pt,
)
```

### Code Block Customization

Control how code blocks are rendered:

```typst
#let config = (
  // Engine selection: "codly" (default), "builtin", or "custom"
  codeblock-engine: "codly",

  // For custom engine
  codeblock-custom-show: none,       // Function: (raw) => { ... }

  // Codly configuration dictionary (only used when codeblock-engine: "codly")
  // All parameters are optional; defaults are provided for common options
  // Users can add ANY codly parameter here
  codly-options: (
    // Examples of parameters you can set:
    // languages: codly-languages,   // Language definitions
    // number-format: num => [...],  // Line number formatting
    // zebra-fill: luma(250),        // Alternate row backgrounds
    // fill: rgb("f6f6f6"),          // Background color
    // stroke: 1pt + rgb("e6e6e6"),  // Border
    // ... any other codly parameter
  ),
)
```

**Default values (automatically applied if not specified):**

- `languages`: `codly-languages` (all built-in languages)
- `number-format`: `none` (no line numbers)
- `zebra-fill`: `none` (no zebra stripes)
- `fill`: `cfg.codeblock-background` (uses color config)
- `stroke`: `1pt + cfg.codeblock-border` (uses color config)

**Enable line numbers and zebra stripes:**

```typst
#let config = (
  codly-options: (
    number-format: num => text(fill: gray)[#num],
    zebra-fill: luma(250),
  ),
)
```

**Advanced: Override multiple parameters:**

```typst
#let config = (
  codly-options: (
    languages: my-custom-langs,  // Custom language definitions
    number-format: num => text(fill: blue)[#num],
    zebra-fill: rgb("f0f8f8"),
    fill: rgb("fafafa"),
    stroke: 2pt + rgb("4a9eff"),
    // You can add ANY codly parameter here, not just the common ones
    display-name: true,
    display-icon: false,
    // ... etc
  ),
)
```

!!! warning "Important"
When using `codeblock-engine: "codly"`, **do not** manually call `show: codly-init.with()` or `codly(...)` in your `custom.typ` file. All codly configuration should be done through the `codly-options` dictionary to avoid conflicts.

**Using builtin Typst rendering:**

```typst
#let config = (
  codeblock-engine: "builtin",
  codeblock-background: rgb("f0f0f0"),
  codeblock-border: rgb("d0d0d0"),
)
```

**Custom code block renderer:**

```typst
#let my-code-renderer(it) = {
  if it.block {
    // Block code: fancy styling
    block(
      width: 100%,
      fill: gradient.linear(rgb("e8f4f8"), rgb("f0f8ff")),
      stroke: 2pt + rgb("4a9eff"),
      inset: 12pt,
      radius: 5pt,
      breakable: true,
    )[
      #if it.lang != none {
        text(weight: "bold", fill: rgb("4a9eff"))[#it.lang]
        linebreak()
      }
      #it
    ]
  } else {
    // Inline code: simple box
    box(
      fill: rgb("f5f5f5"),
      inset: (x: 3pt, y: 1pt),
      radius: 2pt,
    )[#it]
  }
}

#let config = (
  codeblock-engine: "custom",
  codeblock-custom-show: my-code-renderer,
)
```

### Header Customization

Control page headers:

```typst
#let config = (
  // Mode: "chapter" (default), "none", or "custom"
  header-mode: "chapter",

  // Font size for default header
  header-size: 10pt,

  // Alignment for default header
  header-alignment: right,       // left, center, or right

  // Line stroke below header
  header-line-stroke: 0.5pt,

  // For custom mode
  header-custom-function: none,  // Function: (loc, cfg) => { ... }
)
```

**Disable headers:**

```typst
#let config = (
  header-mode: "none",
)
```

**Left-aligned chapter headers:**

```typst
#let config = (
  header-alignment: left,  // Change from default 'right'
)
```

**Custom header function:**

```typst
#let my-header(loc, cfg) = {
  if loc.page() <= 1 { return }

  align(right)[
    #text(10pt, fill: gray)[
      My Documentation · Page #loc.page()
    ]
  ]
  line(length: 100%, stroke: 0.5pt + gray)
}

#let config = (
  header-mode: "custom",
  header-custom-function: my-header,
)
```

### Footer Customization

Control page footers:

```typst
#let config = (
  // Mode: "page-number" (default), "none", or "custom"
  footer-mode: "page-number",

  // Font size for default footer
  footer-size: 10pt,

  // Alignment for default footer
  footer-alignment: center,  // left, center, or right

  // Show footer on part pages?
  footer-show-on-part-pages: false,

  // For custom mode
  footer-custom-function: none,  // Function: (loc, cfg) => { ... }
)
```

**Right-aligned page numbers:**

```typst
#let config = (
  footer-alignment: right,
)
```

**Custom footer with copyright:**

```typst
#let my-footer(loc, cfg) = {
  if loc.page() <= 1 { return }

  // Skip part pages
  let parts_on_page = query(heading.where(level: 1)).filter(h => h.location().page() == loc.page())
  if parts_on_page.len() > 0 { return }

  grid(
    columns: (1fr, auto, 1fr),
    align: (left, center, right),
    text(9pt, fill: gray)[© 2025 My Company],
    text(11pt)[#counter(page).display()],
    text(9pt, fill: gray)[Internal Documentation],
  )
}

#let config = (
  footer-mode: "custom",
  footer-custom-function: my-footer,
)
```

### Page Numbering Customization

Control page number format:

```typst
#let config = (
  // Format for frontmatter (title page, TOC)
  page-numbering-frontmatter: "i",  // Roman numerals

  // Format for main content
  page-numbering-mainmatter: "1",   // Arabic numerals

  // Custom numbering function (overrides both above)
  page-numbering-custom: none,      // Function: (nums, cfg) => { ... }
)
```

**Different numbering formats:**

```typst
#let config = (
  page-numbering-frontmatter: "I",    // Roman uppercase
  page-numbering-mainmatter: "1 / 1", // Page X of Y format
)
```

**Chinese page numbering:**

```typst
#let chinese-page-number(nums, cfg) = {
  let page-num = nums.first()
  [第 #page-num 页]  // "Page N" in Chinese
}

#let config = (
  page-numbering-custom: chinese-page-number,
)
```

**Complex page numbering:**

```typst
#let fancy-numbering(nums, cfg) = {
  let page-num = nums.first()
  // Add prefix based on context
  context {
    let loc = here()
    let chapters = query(heading.where(level: 2))

    // Find current chapter
    let ch-num = 0
    for ch in chapters {
      if ch.location().page() <= loc.page() {
        ch-num = ch-num + 1
      }
    }

    if ch-num > 0 {
      [Ch.#ch-num-#page-num]
    } else {
      [#page-num]
    }
  }
}

#let config = (
  page-numbering-custom: fancy-numbering,
)
```

## Example Customizations

### Complete Example: Enterprise Style

```typst
// docs/src/assets/custom.typ

// Custom header showing chapter info
#let my-header(loc, cfg) = {
  if loc.page() <= 1 { return }

  let parts_on_page = query(heading.where(level: 1)).filter(h => h.location().page() == loc.page())
  if parts_on_page.len() > 0 { return }

  let chapters_on_page = query(heading.where(level: 2)).filter(h => h.location().page() == loc.page())
  if chapters_on_page.len() > 0 { return }

  // Find current chapter
  let all_chapters = query(heading.where(level: 2))
  let current_chapter = none
  for ch in all_chapters {
    if ch.location().page() <= loc.page() {
      current_chapter = ch
    } else {
      break
    }
  }

  if current_chapter != none {
    grid(
      columns: (1fr, auto),
      align: (left, right),
      text(10pt, fill: cfg.dark-blue)[#current_chapter.body],
      text(10pt, fill: gray)[Page #loc.page()],
    )
    line(length: 100%, stroke: 0.5pt + cfg.dark-blue)
  }
}

// Custom footer
#let my-footer(loc, cfg) = {
  if loc.page() <= 1 { return }

  let parts_on_page = query(heading.where(level: 1)).filter(h => h.location().page() == loc.page())
  if parts_on_page.len() > 0 { return }

  align(center)[
    #text(10pt)[#counter(page).display()]
  ]
}

#let config = (
  // Code blocks with line numbers
  codly-options: (
    number-format: num => text(fill: gray)[#num],
  ),

  // Custom header and footer
  header-mode: "custom",
  header-custom-function: my-header,
  footer-mode: "custom",
  footer-custom-function: my-footer,

  // Custom colors
  dark-blue: rgb("2e5cb8"),
  light-blue: rgb("5a8dd6"),

  // Larger text
  text-size: 12pt,
  code-size: 10pt,
)
```

### Modern Dark Theme

```typst
#let config = (
  light-blue: rgb("61afef"),
  dark-blue: rgb("528bff"),
  codeblock-background: rgb("282c34"),
  text-font: ("SF Pro Display", "Inter", "DejaVu Sans"),
  text-size: 11pt,
  codly-options: (
    number-format: num => text(fill: gray)[#num],
  ),
)
```

### Academic Style

```typst
#let config = (
  text-font: ("Times New Roman", "Liberation Serif"),
  code-font: ("Courier New", "Liberation Mono"),
  text-size: 12pt,
  code-size: 10pt,
  heading-size-chapter: 16pt,
  header-mode: "none",
  footer-alignment: center,
)
```

### Compact Layout

```typst
#let config = (
  text-size: 10pt,
  code-size: 8pt,
  table-inset: 6pt,
  quote-inset: (left: 10pt, right: 10pt, top: 8pt, bottom: 8pt),
  codeblock-engine: "builtin",
)
```

## Advanced Customization

### Custom Document Content

The `custom.typ` file can contain not just configuration, but also **document content** like custom title pages, prefaces, or dedications. This content will be inserted at the beginning of your document, before the main content.

#### Custom Title Page

To replace the default title page with your own, set `skip-default-titlepage: true` in your config:

```typst
// docs/src/assets/custom.typ

#let config = (
  skip-default-titlepage: true,  // Skip the default title page
  // ... other config
)

// Your custom title page
#page(
  margin: (left: 2cm, right: 2cm, bottom: 3cm, top: 2cm),
  header: none,
  footer: none,
  numbering: none,
)[
  #align(center)[
    #v(3cm)
    #image("logo.png", width: 150pt)
    #v(2cm)
    #text(size: 48pt, weight: "bold")[My Amazing Package]
    #v(1cm)
    #text(size: 24pt)[Internal Documentation]
    #v(1fr)
    #text(size: 14pt, fill: gray)[Confidential • Company Use Only]
  ]
]

// Optional: Add your own table of contents
#outline(depth: 3, indent: true)
#pagebreak()
```

**Important:** When `skip-default-titlepage: true`, you are responsible for:

- Creating your title page
- Adding the table of contents (if desired) with `#outline()`
- Adding page breaks (`#pagebreak()`) as needed

#### Adding Preamble Content

You can add content **before** the main documentation without replacing the title page:

```typst
// docs/src/assets/custom.typ

#let config = (
  // ... your config, skip-default-titlepage NOT set
)

// Content after default title page and TOC, before main content
// This appears at the start of the main matter (page 1)

#align(center)[
  #strong[Preface]

  #v(1em)

  This documentation was automatically generated from source code.
  For the latest version, visit our website.
]

#pagebreak()
```

#### Full Example: Corporate Branding

```typst
// docs/src/assets/custom.typ

#let config = (
  skip-default-titlepage: true,
  light-blue: rgb("0066cc"),
  text-font: ("Helvetica Neue", "Arial"),
)

// Custom cover page
#page(
  margin: 0pt,
  header: none,
  footer: none,
  numbering: none,
)[
  // Full-page branded background
  #rect(
    width: 100%,
    height: 100%,
    fill: gradient.linear(rgb("0066cc"), rgb("003d7a"), angle: 45deg)
  )[
    #align(center + horizon)[
      #text(size: 60pt, fill: white, weight: "bold")[ACME Corp]
      #v(2cm)
      #text(size: 36pt, fill: white)[Product Documentation]
      #v(1fr)
      #text(size: 16pt, fill: white)[Version 2.0 • December 2025]
    ]
  ]
]

// Legal notice page
#page(
  header: none,
  footer: none,
  numbering: none,
)[
  #v(1fr)
  #align(center)[
    #text(size: 10pt)[
      © 2025 ACME Corporation. All rights reserved.

      This document is confidential and proprietary.
    ]
  ]
  #v(1fr)
]

// Table of contents with custom styling
#page(numbering: "i")[
  #align(center)[
    #text(size: 24pt, weight: "bold")[Contents]
  ]
  #v(2em)
  #outline(depth: 2, indent: true)
]

#pagebreak()
```

This is useful for:

- **Corporate documentation**: Add branding, confidentiality notices, approval signatures
- **Academic papers**: Add author affiliations, abstracts, acknowledgments
- **Books**: Add dedications, forewords, prefaces
- **Internal docs**: Add disclaimers, distribution lists, revision history

### Custom Functions

You can define custom Typst functions:

```typst
// docs/src/assets/custom.typ

#let config = (
  // ... your config
)

// Custom function for highlighted boxes
#let highlight(body) = {
  rect(
    fill: rgb("fff3cd"),
    stroke: rgb("ffc107") + 1pt,
    inset: 10pt,
    radius: 3pt,
    body
  )
}

// Custom header styling
#let custom-header(body) = {
  set text(fill: rgb("2c3e50"))
  strong(body)
}
```

**Note:** When using `codeblock-engine: "custom"`, your custom show rule replaces the entire code rendering logic. The `codeblock-custom-show` function receives the raw content and must handle both block and inline code.

### Override Show Rules

For less invasive customizations, you can add show rules in `custom.typ` that work alongside the default rendering:

```typst
// Custom link styling (works with any configuration)
#show link: it => {
  underline(text(fill: rgb("0066cc"), it))
}

// Emphasize strong text more
#show strong: it => {
  text(fill: rgb("c93d39"), weight: "bold", it)
}
```

**Important:** Show rules added in `custom.typ` are applied in order. If you're using `codeblock-engine: "custom"`, your custom renderer is already a show rule, so additional `show raw:` rules may conflict.

## Complete Configuration Reference

Here's a complete list of all available configuration options with their defaults:

```typst
#let config = (
  // === Colors ===
  light-blue: rgb("6b85dd"),
  dark-blue: rgb("4266d5"),
  light-red: rgb("d66661"),
  dark-red: rgb("c93d39"),
  light-green: rgb("6bab5b"),
  dark-green: rgb("3b972e"),
  light-purple: rgb("aa7dc0"),
  dark-purple: rgb("945bb0"),
  codeblock-background: rgb("f6f6f6"),
  codeblock-border: rgb("e6e6e6"),

  // === Typography ===
  text-font: ("Inter", "DejaVu Sans"),
  code-font: ("JetBrains Mono", "DejaVu Sans Mono"),
  text-size: 11pt,
  code-size: 9pt,
  heading-size-title: 24pt,
  heading-size-part: 18pt,
  heading-size-chapter: 18pt,
  heading-size-part-label: 14pt,
  heading-size-chapter-label: 14pt,
  heading-size-section: 14pt,
  heading-size-subsection: 13pt,
  heading-size-subsubsection: 12pt,
  admonition-title-size: 12pt,
  metadata-size: 12pt,

  // === Code Block Customization ===
  codeblock-engine: "codly",         // "codly" | "builtin" | "custom"
  codeblock-custom-show: none,       // Function: (raw) => { ... }
  codly-options: (
    // Empty by default; users can add any codly parameters
    // Default values are automatically applied:
    //   languages: codly-languages
    //   number-format: none
    //   zebra-fill: none
    //   fill: cfg.codeblock-background
    //   stroke: 1pt + cfg.codeblock-border
  ),

  // === Header Customization ===
  header-mode: "chapter",            // "chapter" | "none" | "custom"
  header-alignment: right,           // left | center | right
  header-custom-function: none,      // Function: (loc, cfg) => { ... }
  header-line-stroke: 0.5pt,
  header-size: 10pt,

  // === Footer Customization ===
  footer-mode: "page-number",        // "page-number" | "none" | "custom"
  footer-size: 10pt,
  footer-alignment: center,          // left | center | right
  footer-custom-function: none,      // Function: (loc, cfg) => { ... }
  footer-show-on-part-pages: false,

  // === Page Numbering ===
  page-numbering-frontmatter: "i",   // Roman numerals
  page-numbering-mainmatter: "1",    // Arabic numerals
  page-numbering-custom: none,       // Function: (nums, cfg) => { ... }

  // === Layout ===
  outline-number-spacing: 0.5em,
  outline-indent-step: 1em,
  outline-part-spacing: 0.5em,
  outline-filler-spacing: 10pt,
  outline-line-spacing: -0.2em,
  table-stroke-width: 0.5pt,
  table-stroke-color: rgb("cccccc"),
  table-inset: 8pt,
  quote-background: rgb("f8f8f8"),
  quote-border-color: rgb("cccccc"),
  quote-border-width: 4pt,
  quote-inset: (left: 15pt, right: 15pt, top: 10pt, bottom: 10pt),
  quote-radius: (right: 3pt),

  // === Admonitions ===
  admonition-colors: (
    default: rgb("363636"),
    danger: rgb("da0b00"),
    warning: rgb("ffdd57"),
    note: rgb("209cee"),
    info: rgb("209cee"),
    tip: rgb("22c35b"),
    compat: rgb("1db5c9"),
  ),
  admonition-titles: (
    default: "Note",
    danger: "Danger",
    warning: "Warning",
    note: "Note",
    info: "Info",
    tip: "Tip",
    compat: "Compatibility",
  ),
  admonition-title-inset: (left: 1em, right: 5pt, top: 5pt, bottom: 5pt),
  admonition-title-radius: (top: 5pt),
  admonition-title-color: white,
  admonition-content-inset: 10pt,
  admonition-content-radius: (bottom: 5pt),

  // === Title Page ===
  skip-default-titlepage: false,
)
```

## Testing Your Style

### Preview Quickly

Use `platform="none"` for fast iteration:

```julia
format = DocumenterTypst.Typst(platform = "none")
```

Then compile manually:

```bash
cd docs/build
typst compile YourPackage.typ
```

### Compare Versions

```bash
# Build with custom styling
julia docs/make.jl

# Compare with default
mv docs/build/YourPackage.pdf docs/build/custom.pdf
rm docs/src/assets/custom.typ
julia docs/make.jl
```

## Font Installation

### Using System Fonts

Typst automatically finds system fonts. No configuration needed for:

- **macOS**: All installed fonts
- **Linux**: Fonts in `~/.fonts` and `/usr/share/fonts`
- **Windows**: Fonts in `C:\Windows\Fonts`

### Custom Font Directories

```julia
format = DocumenterTypst.Typst(
    platform = "native",
    typst = `typst --font-path /path/to/fonts`
)
```

### Embedding Fonts

For reproducible builds, use `Typst_jll` which includes basic fonts, or use Docker.

## Troubleshooting

### Font Not Found

**Problem**: "font not found" error

**Solutions**:

1. Check font is installed: `typst fonts` (native) or check system fonts
2. Use fallback: `text-font: ("PreferredFont", "Fallback", "DejaVu Sans")`
3. Specify font path: `typst --font-path /custom/path`

### Colors Not Applying

**Problem**: Custom colors don't show up

**Solutions**:

1. Ensure `custom.typ` is in `docs/src/assets/`
2. Check syntax: use `rgb("rrggbb")` format
3. Verify config variable name matches default

### Layout Issues

**Problem**: Spacing or alignment looks wrong

**Solutions**:

1. Check units: use `pt`, `em`, `%` explicitly
2. Test with debug output: `DOCUMENTER_TYPST_DEBUG=1`
3. Compare with default template

## Example Templates

DocumenterTypst includes a comprehensive example file showing all customization options:

**File location:** `docs/src/assets/custom.typ.example`

This file contains 10 complete examples demonstrating:

1. Simple configuration changes (line numbers, zebra stripes)
2. Using builtin Typst rendering (no codly)
3. Disabling headers
4. Custom header functions
5. Custom footers with copyright
6. Chinese page numbering
7. Custom code block renderers
8. Comprehensive customization combining multiple features
9. Minimal header/footer configuration
10. Different page numbering formats

**Usage:** Copy this file to `docs/src/assets/custom.typ`, uncomment the example you want to use, and modify as needed.

```bash
cp docs/src/assets/custom.typ.example docs/src/assets/custom.typ
# Edit custom.typ and uncomment desired example
```

## Resources

- [Typst Documentation](https://typst.app/docs/)
- [Typst Guide](https://typst.app/docs/guides/)

## Examples Gallery

See [Examples](../examples/advanced.md) for complete styling examples.
