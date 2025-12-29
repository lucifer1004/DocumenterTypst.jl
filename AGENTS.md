# AGENTS.md

**For AI Agents and Contributors**: This document describes the architecture, data flow, and code organization of DocumenterTypst.jl.

---

## Critical Rules

1. **Never break backward compatibility**: Any change that breaks existing user documentation builds is a bug.
2. **All user-visible changes require a changelog entry** in `CHANGELOG.md` under "Unreleased" section (unless marked "Skip Changelog").
3. **Code style**: Follow Julia standard conventions. Use `just format` (Runic for Julia, markdownlint-cli2 for Markdown) before committing.
4. **Test coverage**: Add tests for all new Markdown node types or Typst output features.
5. **Detect VCS correctly**: Always check for version control system before suggesting workflows (see "VCS Detection" below).

---

## VCS Detection (For AI Agents)

**Before suggesting any Git/Jujutsu commands**, detect the project's VCS:

### Detection Strategy

```bash
# Check for hidden VCS directories (list_dir tool doesn't show hidden files!)
ls -a | grep -E "^\.(git|jj|hg|svn)"
```

### Workflow Selection

| VCS Detected          | Workflow to Use                      | Example Commands                                   |
| --------------------- | ------------------------------------ | -------------------------------------------------- |
| `.jj` (Jujutsu)       | Jujutsu change-based                 | `jj new -m "msg"`, `jj describe`, `jj git push`    |
| `.git` only           | Git branch-based                     | `git checkout -b branch`, `git commit`, `git push` |
| Both `.jj` and `.git` | **Prefer Jujutsu** (explicit choice) | Jujutsu commands + note Git interop available      |

### Critical Notes

- **List tools may hide dotfiles**: Always use `ls -a` or equivalent terminal command
- **Jujutsu often coexists with Git**: If both present, prefer Jujutsu workflow but mention Git compatibility
- **This project uses**: Jujutsu (`.jj` present) with Git interop (`.git` also present)

---

## What This Project Does

**Input**: Documenter.jl's AST (Abstract Syntax Tree) from Markdown documentation  
**Output**: Professional PDF via Typst typesetting system

**Core Value**: Compile large documentation projects to PDF in < 60 seconds vs several minutes with LaTeX.

---

## Architecture Overview

### Data Flow

```
User Markdown Files
  ↓
Documenter.jl (parsing, cross-references, etc.)
  ↓
Documenter.Document (unified AST with MarkdownAST nodes)
  ↓
TypstWriter.render_typst() (convert AST to Typst code)
  ↓
.typ file (Typst markup language)
  ↓
Typst Compiler (via Typst_jll / native)
  ↓
PDF Output
```

### Key Design Decision

DocumenterTypst is a **Documenter plugin**, not a standalone tool. It:

- Reuses Documenter's Markdown parsing, cross-reference resolution, and page management
- Only handles the "AST → Typst → PDF" conversion
- Follows the same plugin architecture as DocumenterVitepress.jl

---

## Code Organization

### Entry Point

- **`src/DocumenterTypst.jl`**: Module definition, exports `Typst` format struct. Minimal glue code.

### Core Logic

- **`src/TypstWriter.jl`**: The entire conversion engine
  - `Typst` struct: Configuration (platform, version, typst executable path)
  - `render_typst()`: Main orchestrator, generates `.typ` file and compiles to PDF
  - `convert()` methods: AST node → Typst code translation (50+ node types supported)
  - Helper functions: Label generation, escaping, path handling

### Typst Template

- **`assets/documenter.typ`**: Default Typst template defining PDF styling
  - Page layout (margins, headers, footers)
  - Typography (fonts, colors, spacing)
  - Admonition boxes (info, warning, danger, etc.)
  - Code block highlighting
  - Table of contents generation

**User Customization**: Users can override styles by providing `src/assets/custom.typ` in their docs project.

### Tests

- **`test/runtests.jl`**: Unit tests for all MarkdownAST node conversions
- **`test/integration/`**: Integration tests that compile full documentation projects
  - **`fixtures/`**: Test fixtures for different scenarios

### Documentation

- **`docs/src/manual/`**: User guides (getting started, configuration, styling, math support, troubleshooting)
- **`docs/src/examples/`**: Complete examples (advanced features, migration from LaTeX)
- **`docs/src/api/`**: API reference

---

## Key Data Structures

### `Typst` (Format Configuration)

```julia
struct Typst <: Documenter.Writer
    platform::String   # "typst" | "native" | "none"
    version::String    # Semantic version for filename (e.g., "1.0.0")
    typst::Union{Nothing, String, Cmd}  # Custom path to typst executable
    optimize_pdf::Bool  # Whether to run PDF optimization (via pdfcpu)
    use_system_fonts::Bool  # Allow system font lookup
    font_paths::Vector{String}  # Additional font directories
end
```

### Documenter's AST Nodes

DocumenterTypst handles 50+ MarkdownAST node types. Critical ones:

- **Structural**: `Document`, `Heading`, `Paragraph`, `List`, `BlockQuote`
- **Inline**: `Text`, `Code`, `Strong`, `Emph`, `Link`, `Image`
- **Advanced**: `CodeBlock`, `Table`, `Math`, `Admonition`, `Footnote`
- **Documenter-specific**: `@docs` blocks, `@example` blocks, cross-references

### Conversion Strategy

Each node type has a `convert(io::IO, node::Node, doc::Document)` method that:

1. Extracts data from the AST node
2. Generates corresponding Typst markup
3. Recursively converts child nodes

Example: `Heading` → `#heading(level: 1, "Title Text")`

---

## Extension Points

### Adding Support for a New Markdown Node Type

1. **Locate the node type** in Documenter's MarkdownAST
2. **Add a `convert()` method** in `src/TypstWriter.jl`:

   ```julia
   function convert(io::IO, node::Node{T}, doc::Documenter.Document) where {T <: NewNodeType}
       # Extract data from node.element
       # Write Typst code to io
       # Recursively convert children if needed
   end
   ```

3. **Add tests** in `test/runtests.jl`:

   ```julia
   @testset "NewNodeType" begin
       # Test various edge cases
   end
   ```

### Customizing PDF Styling

**Option 1: User-level customization** (recommended for end users)

- Create `docs/src/assets/custom.typ` in the user's documentation project
- Override colors, fonts, layout settings via the `config` dictionary
- See [Styling Guide](https://lucifer1004.github.io/DocumenterTypst.jl/stable/manual/styling/)

**Option 2: Template modification** (for forking/advanced needs)

- Edit `assets/documenter.typ` directly
- Changes apply to all projects using your fork

### Adding a New Compilation Backend

1. **Add platform option** in `Typst` struct validation
2. **Implement compilation logic** in `compile_typst()` function:

   ```julia
   if platform == "new_backend"
       # Custom compilation logic
   end
   ```

3. **Update documentation** in `docs/src/manual/configuration.md`

---

## Testing Strategy

### Unit Tests (`test/runtests.jl`)

- Test each MarkdownAST node type in isolation
- Verify correct Typst code generation
- Edge cases: empty nodes, special characters, nested structures

### Integration Tests (`test/typst_backend/`)

- Compile full documentation projects with different platforms
- Verify PDF generation succeeds
- Test real-world scenarios: Julia code examples, math, admonitions

**Running Tests**:

```bash
just test              # Unit tests
just test-integration  # Integration tests (default: Typst_jll)
just test-integration none # Fast test (no compilation)
```

---

## Dependencies

### Core Dependencies

- **Documenter.jl**: AST generation, cross-reference resolution
- **MarkdownAST.jl**: AST node types
- **Typst_jll.jl**: Bundled Typst compiler (platform="typst")

### Math Rendering

- **mitex**: LaTeX math → Typst math conversion (via Typst package)
- Users can choose: LaTeX syntax (`\alpha`) or native Typst syntax (`alpha`)

---

## Debugging

### Enable Debug Mode

Set environment variable to save intermediate `.typ` files:

```julia
ENV["DOCUMENTER_TYPST_DEBUG"] = "debug-output"
makedocs(format = DocumenterTypst.Typst())
# .typ files saved to debug-output/ directory
```

### Common Issues

1. **Compilation fails**: Check `platform` setting matches available compiler
2. **Math rendering broken**: Verify LaTeX syntax is correct (mitex is strict)
3. **Styling not applied**: Ensure `custom.typ` is in `docs/src/assets/` directory
4. **Cross-references broken**: Check that Documenter's `pages` order is correct

See [Troubleshooting Guide](https://lucifer1004.github.io/DocumenterTypst.jl/stable/manual/troubleshooting/) for details.

---

## Development Workflow

### Setup

```bash
git clone https://github.com/lucifer1004/DocumenterTypst.jl
cd DocumenterTypst.jl
just dev  # Install dependencies
```

### Common Tasks

```bash
just test           # Run unit tests
just format         # Auto-format Julia code (Runic) and Markdown (markdownlint-cli2)
just docs           # Build HTML documentation
just docs-typst     # Build PDF documentation
just changelog      # Generate changelog from CHANGELOG.md
just clean          # Remove build artifacts
```

### Making Changes

**This project uses Jujutsu (jj) for version control** (`.jj` directory present).

1. Create a new change: `jj new -m "Add feature"`
2. Make changes, add tests
3. Run `just format` and `just test`
4. Add changelog entry to `CHANGELOG.md` under "Unreleased"
5. Describe your changes: `jj describe`
6. Create PR: Use `jj git push` or GitHub CLI

**Git interop**: The repository also has `.git`, so standard Git commands work if preferred.

---

## Design Philosophy

### Simplicity Over Abstraction

- Single-file core logic (`TypstWriter.jl`) instead of complex module hierarchy
- Direct AST → string conversion, no intermediate representation
- Minimal configuration surface with sensible defaults

### Backward Compatibility First

- Support all existing Documenter Markdown syntax
- LaTeX math via mitex for zero-migration cost
- Default to safe, widely-compatible Typst_jll backend

### Performance Through Tooling

- Typst's incremental compilation is inherently fast
- No optimization needed in Julia code—just generate correct Typst markup

---

## Related Resources

- **Documenter.jl API**: https://documenter.juliadocs.org/stable/
- **Typst Documentation**: https://typst.app/docs/
- **mitex (LaTeX → Typst)**: https://github.com/mitex-rs/mitex
- **DocumenterVitepress.jl** (inspiration): https://github.com/LuxDL/DocumenterVitepress.jl

---

## Questions for AI Agents

**Q: Where do I add support for a new Markdown feature?**  
A: Add a `convert()` method in `src/TypstWriter.jl` for the corresponding MarkdownAST node type.

**Q: How do I change the PDF appearance?**  
A: Modify `assets/documenter.typ` or guide users to create `docs/src/assets/custom.typ`.

**Q: How does cross-referencing work?**  
A: Documenter resolves references during AST building. TypstWriter generates Typst `#label()` and `#link()` calls using `make_label_id()`.

**Q: Why is compilation slow?**  
A: Use `platform="typst"` (Typst_jll) for best performance. Avoid `platform="none"` for production.

**Q: How do I test changes without waiting for compilation?**  
A: Use `just test-backend none` (generates `.typ` only, no PDF compilation).
