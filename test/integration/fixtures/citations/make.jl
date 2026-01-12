using Documenter
using DocumenterTypst
using DocumenterCitations

bib = CitationBibliography(joinpath(@__DIR__, "src", "refs.bib"))

makedocs(;
    sitename = "CitationsTest",
    authors = "Test Suite",
    format = DocumenterTypst.Typst(
        platform = get(ENV, "TYPST_PLATFORM", "typst"),
        version = "0.1.0",
        date = "Jan 1, 2025",  # Fixed date for reproducible tests
    ),
    pages = [
        "Home" => "index.md",
        "Chapter 1" => "chapter1.md",
        "Chapter 2" => "chapter2.md",
        "References" => "references.md",
    ],
    plugins = [bib],
    build = "build",
    remotes = nothing,  # Disable Git remote detection for tests
)
