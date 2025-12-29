using Markdown
using MarkdownAST

# 修复后的格式
md_text_fixed = """
!!! note "Internal APIs"
    The `TypstWriter` module is not part of the public API and may change without notice.
    If you need to extend or customize the Typst rendering, please open an issue to discuss
    making specific APIs public.
"""

println("=== 修复后的Markdown.jl解析结果 ===")
md = Markdown.parse(md_text_fixed)
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
            text_preview = length(node.element.text) > 50 ? node.element.text[1:50] * "..." : node.element.text
            println(indent, "  text: \"", text_preview, "\"")
        end
        for child in node.children
            print_tree(child, depth + 1)
        end
    end
end

println("=== AST结构（修复后）===")
print_tree(ast)
