using Documenter
using DocumenterTypst

# Define a simple test module
module EnhancedTypstTest

    """
        greet(name::String) -> String

    Greet a person by name.

    # Examples

    ```julia
    greet("Alice")
    # Output: "Hello, Alice!"
    ```
    """
    function greet(name::String)
        return "Hello, $(name)!"
    end

    """
        add_numbers(a::Number, b::Number) -> Number

    Add two numbers together.

    This is a simple addition function used for testing
    the `@typst-docs` preprocessing directive.

    # Arguments

    - `a`: First number
    - `b`: Second number

    # Returns

    The sum of `a` and `b`.
    """
    function add_numbers(a::Number, b::Number)
        return a + b
    end

    export greet, add_numbers

end

makedocs(;
    sitename = "EnhancedTypstTest",
    authors = "Test Suite",
    modules = [EnhancedTypstTest],
    format = DocumenterTypst.Typst(
        platform = get(ENV, "TYPST_PLATFORM", "typst"),
        version = "0.1.0"
    ),
    pages = [
        "Home" => "index.md",
        "Enhanced Typst" => "enhanced.typ",
    ],
    build = "build",
    remotes = nothing,  # Disable Git remote detection for tests
    warnonly = [:missing_docs],  # Don't error on missing docs (they're in .typ file)
)
