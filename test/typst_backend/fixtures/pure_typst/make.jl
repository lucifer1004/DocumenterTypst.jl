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
        "simple.typ",  # depth=1, no title => offset=0
        "Simple Typst" => "simple.typ",  # depth=1, with title => offset=1
        "Advanced" => [
            "Nested with Image" => "nested/with_image.typ",  # depth=2, with title => offset=2
            "Deep" => [
                "Level 3" => "nested/level3.typ",  # depth=3, with title => offset=3
            ],
        ],
    ],
    build = "build",
    remotes = nothing,  # Disable Git remote detection for tests
)
