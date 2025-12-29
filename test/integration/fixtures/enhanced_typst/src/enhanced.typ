= Enhanced Typst Page

This page demonstrates Documenter directives in Typst files.

== Custom Typst Content

You can use native Typst syntax freely:

#table(
  columns: 3,
  [Name], [Age], [City],
  [Alice], [25], [NYC],
  [Bob], [30], [LA],
)

== API Documentation

The following function documentation is generated via `@typst-docs`:

// @typst-docs EnhancedTypstTest.greet
// @typst-docs EnhancedTypstTest.add_numbers

== Code Examples

The following example is executed and rendered via `@typst-example`:

// @typst-example
// # The module is already loaded in the context
// result = EnhancedTypstTest.add_numbers(5, 7)
// println("Result: $result")
// @typst-example-end

== Cross References

You can reference functions: // @typst-ref EnhancedTypstTest.greet

== More Native Typst

#align(center)[
  #text(size: 16pt, weight: "bold")[
    This is centered and bold!
  ]
]
