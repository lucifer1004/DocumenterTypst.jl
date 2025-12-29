# Math Support

DocumenterTypst supports both native Typst math and LaTeX math syntax.

## Which Should I Use?

| Use Case                 | Recommendation              | Reason                      |
| ------------------------ | --------------------------- | --------------------------- |
| **New projects**         | Native Typst math           | Faster, cleaner, better UX  |
| **Migrating from LaTeX** | Keep LaTeX math (via mitex) | Works as-is, zero migration |
| **Mixed documentation**  | Both (can coexist)          | Flexibility                 |

## Native Typst Math (Recommended)

For new projects, use Typst's native math syntax.

### Display Math

````markdown
```math typst
sum_(i=1)^n i = (n(n+1))/2
```
````

**Rendered output**:

```math typst
sum_(i=1)^n i = (n(n+1))/2
```

### Complex Equations

````markdown
```math typst
integral_0^infinity e^(-x^2) dif x = sqrt(pi)/2
```
````

### Matrices

````markdown
```math typst
mat(
  1, 2, ..., 10;
  2, 2, ..., 10;
  dots.v, dots.v, dots.down, dots.v;
  10, 10, ..., 10;
)
```
````

### Advantages

- **Faster compilation**: No LaTeX→Typst conversion
- **Better error messages**: Typst's errors are clearer
- **More features**: Access to Typst-specific functionality
- **Cleaner syntax**: Less verbose than LaTeX

### Syntax Comparison

| Feature     | LaTeX                           | Typst                |
| ----------- | ------------------------------- | -------------------- |
| Fractions   | `\frac{a}{b}`                   | `a/b` or `frac(a,b)` |
| Subscript   | `x_{ij}`                        | `x_(i j)`            |
| Superscript | `x^{2}`                         | `x^2`                |
| Integral    | `\int_a^b`                      | `integral_a^b`       |
| Sum         | `\sum_{i=1}^n`                  | `sum_(i=1)^n`        |
| Matrices    | `\begin{matrix}...\end{matrix}` | `mat(...)`           |

See [Typst Math Documentation](https://typst.app/docs/reference/math/) for complete syntax reference.

## LaTeX Math (For Compatibility)

For backward compatibility with existing Documenter documentation, LaTeX math is supported via [mitex](https://github.com/mitex-rs/mitex).

### Inline Math

```markdown
The equation `E = mc^2` is Einstein's mass-energy equivalence.
```

**Rendered**: The equation `E = mc^2` is Einstein's mass-energy equivalence.

### Display Math

````markdown
```math
\sum_{i=1}^n i = \frac{n(n+1)}{2}
```
````

**Rendered output**:

```math
\sum_{i=1}^n i = \frac{n(n+1)}{2}
```

### Complex Equations

````markdown
```math
\begin{aligned}
\nabla \times \vec{\mathbf{B}} -\, \frac1c\, \frac{\partial\vec{\mathbf{E}}}{\partial t}
&= \frac{4\pi}{c}\vec{\mathbf{j}} \\
\nabla \cdot \vec{\mathbf{E}} &= 4 \pi \rho \\
\nabla \times \vec{\mathbf{E}}\, +\, \frac1c\, \frac{\partial\vec{\mathbf{B}}}{\partial t}
&= \vec{\mathbf{0}} \\
\nabla \cdot \vec{\mathbf{B}} &= 0
\end{aligned}
```
````

### Supported Features

mitex supports most common LaTeX math commands:

- **Greek letters**: `\alpha`, `\beta`, `\gamma`, ...
- **Operators**: `\sum`, `\prod`, `\int`, `\lim`, ...
- **Relations**: `\leq`, `\geq`, `\approx`, `\equiv`, ...
- **Brackets**: `\left(`, `\right)`, `\big[`, `\Big]`, ...
- **Matrices**: `\begin{matrix}`, `\begin{pmatrix}`, ...
- **Environments**: `aligned`, `cases`, `array`, ...

### Known Limitations

Some advanced LaTeX packages are not supported:

- Custom LaTeX packages (tikz, pgfplots, etc.)
- Complex custom macros
- Some AMSmath extensions

**Workaround**: Use native Typst math for advanced features.

## Migration from LaTeX

### Keep Using LaTeX Math

Your existing LaTeX math **works as-is** via mitex:

````markdown
`\alpha + \beta = \gamma`

```math
\frac{\partial f}{\partial x} = \lim_{h \to 0} \frac{f(x+h) - f(x)}{h}
```
````

No changes required!

### Gradual Migration to Typst

Convert incrementally as you update documentation:

**LaTeX** (old):

````markdown
```math
\sum_{i=1}^n i = \frac{n(n+1)}{2}
```
````

**Typst** (new):

````markdown
```math typst
sum_(i=1)^n i = (n(n+1))/2
```
````

### Mixed Approach

You can use both in the same document:

````markdown
Legacy section with LaTeX: `\sum_{i=1}^n i`

New section with Typst:

```math typst
sum_(i=1)^n i
```
````

## Best Practices

### For New Projects

- **Use native Typst math** for better performance and cleaner syntax
- Learn Typst syntax - it's simpler and more intuitive than LaTeX
- See [Typst tutorial](https://typst.app/docs/tutorial/) for examples

### For Existing Projects

- **Keep LaTeX math** for zero migration cost
- Convert incrementally as you update sections
- Test changes carefully to ensure rendering is correct

### For Large Equations

**Break complex equations into smaller parts**:

```typst
// Bad (hard to read)
$ (a + b + c + d + e + f + g + h + i + j) / (x + y + z) $

// Good (readable)
$ (a + b + c + d + e + f + g + h + i + j) /
  (x + y + z) $
```

## Debugging Math

### Enable Debug Output

```bash
export DOCUMENTER_TYPST_DEBUG="typst-debug"
julia docs/make.jl
```

Check `typst-debug/*.typ` to see how math was converted.

### Common Issues

**Issue**: Math doesn't render correctly

**Solution**:

1. Check for unsupported LaTeX commands
2. Try native Typst syntax instead
3. Enable debug output to see converted code
4. Consult [mitex documentation](https://github.com/mitex-rs/mitex) for supported commands

**Issue**: Spacing looks wrong

**Solution**:

- **LaTeX**: Use `\,`, `\;`, `\quad` for manual spacing
- **Typst**: Use `space`, `h(1em)`, `thin`, `thick` spacing

**Issue**: Inline math not working

**Solution**:

- Use backticks for inline math: `` `E = mc^2` ``
- Native Typst inline math (`$...$`) only works in `.typ` files

## Resources

- [Typst Math Documentation](https://typst.app/docs/reference/math/) - Complete math syntax reference
- [mitex Documentation](https://github.com/mitex-rs/mitex) - LaTeX compatibility layer
- [LaTeX to Typst Guide](https://typst.app/docs/guides/guide-for-latex-users/) - Migration guide
