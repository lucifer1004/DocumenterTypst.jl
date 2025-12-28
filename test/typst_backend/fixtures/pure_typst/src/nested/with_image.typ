= Nested Document with Image

This file tests that images paths work correctly from nested directories.

== Image Test

#figure(
  image("../assets/test.svg", width: 50%),
  caption: [Test image loaded from relative path]
)

== Details

The image above should display correctly because `#include` preserves
the file's relative path context.

=== Subsection

Additional content to test heading levels.
