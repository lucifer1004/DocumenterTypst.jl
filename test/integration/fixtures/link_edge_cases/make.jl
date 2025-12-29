using Documenter
using DocumenterTypst

makedocs(
    sitename = "LinkEdgeCasesTest",
    authors = "Test Suite",
    format = DocumenterTypst.Typst(
        platform = get(ENV, "TYPST_PLATFORM", "none"),
    ),
    pages = [
        "Home" => "index.md",
        "Test Pages" => [
            "Normal Page" => "normal.md",
            "Multiple Headings" => "multiple.md",
            "No Heading" => "no_heading.md",
            "Empty Page" => "empty.md",
            "Only Content" => "only_content.md",
            "Nested" => [
                "Deep Page" => "nested/deep.md",
            ],
        ],
    ],
    doctest = false,
    remotes = nothing,
)
