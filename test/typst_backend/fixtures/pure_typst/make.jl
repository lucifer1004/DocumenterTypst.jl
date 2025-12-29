using Documenter
using DocumenterTypst

makedocs(;
    sitename = "PureTypstTest",
    authors = "Test Suite",
    format = DocumenterTypst.Typst(
        platform = get(ENV, "TYPST_PLATFORM", "typst"),
        version = "0.1.0"
    ),
    pages = [
        "Home" => "index.md",
        "Simple Typst" => "simple.typ",
        "Advanced" => [
            "Nested with Image" => "nested/with_image.typ",
        ],
    ],
    build = "build",
    remotes = nothing,  # Disable Git remote detection for tests
)
