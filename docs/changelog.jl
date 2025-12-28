using Changelog

Changelog.generate(
    Changelog.CommonMark(),
    joinpath(@__DIR__, "..", "CHANGELOG.md");
    repo = "lucifer1004/DocumenterTypst.jl"
)
