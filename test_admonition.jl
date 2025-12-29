using Markdown
using MarkdownAST

md_text = """
!!! note "Internal APIs"
The `TypstWriter` module is not part of the public API and may change without notice.
If you need to extend or customize the Typst rendering, please open an issue to discuss
making specific APIs public.
"""

md = Markdown.parse(md_text)
println("=== Markdown.jl parsed structure ===")
println(md)
println()

ast = MarkdownAST.convert(MarkdownAST.Node, md)

function print_tree(node, depth = 0)
    indent = "  "^depth
    return if node isa MarkdownAST.Node
        println(indent, "Node: ", typeof(node.element))
        if node.element isa MarkdownAST.Admonition
            println(indent, "  title: \"", node.element.title, "\"")
            println(indent, "  category: \"", node.element.category, "\"")
            println(indent, "  children count: ", length(node.children))
        elseif node.element isa MarkdownAST.Paragraph
            println(indent, "  children count: ", length(node.children))
        elseif node.element isa MarkdownAST.Text
            println(indent, "  text: \"", node.element.text, "\"")
        end
        for child in node.children
            print_tree(child, depth + 1)
        end
    end
end

println("=== AST structure ===")
print_tree(ast)
