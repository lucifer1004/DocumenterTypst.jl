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

## Example Customizations

### Modern Dark Theme

```typst
#let config = (
  light-blue: rgb("61afef"),
  dark-blue: rgb("528bff"),
  codeblock-background: rgb("282c34"),
  text-font: ("SF Pro Display", "Inter", "DejaVu Sans"),
  text-size: 11pt,
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
)
```

### Compact Layout

```typst
#let config = (
  text-size: 10pt,
  code-size: 8pt,
  table-inset: 6pt,
  quote-inset: (left: 10pt, right: 10pt, top: 8pt, bottom: 8pt),
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

### Override Show Rules

```typst
// Custom code block styling
#show raw.where(block: true): it => {
  block(
    fill: rgb("1e1e1e"),
    inset: 10pt,
    radius: 5pt,
    stroke: none,
  )[
    #set text(fill: rgb("d4d4d4"))
    #it
  ]
}

// Custom link styling
#show link: it => {
  underline(text(fill: rgb("0066cc"), it))
}
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

## Resources

- [Typst Documentation](https://typst.app/docs/)
- [Typst Guide](https://typst.app/docs/guides/)

## Examples Gallery

See [Examples](../examples/advanced.md) for complete styling examples.
