# Math Support

DocumenterTypst supports both LaTeX and native Typst math syntax.

## LaTeX Math (via mitex)

For backward compatibility with existing Documenter documentation, LaTeX math is supported via [mitex](https://github.com/mitex-rs/mitex).

### Inline Math

```markdown
The equation `E = mc^2` is Einstein's mass-energy equivalence.
```

**Rendered output**: The equation `E = mc^2` is Einstein's mass-energy equivalence.

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

### Supported LaTeX Features

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

For these cases, consider using [native Typst math](#native-typst-math).

## Native Typst Math

For new projects or advanced features, use Typst's native math syntax.

### Syntax

Use `math typst` code blocks:

````markdown
```math typst
sum_(i=1)^n i = (n(n+1))/2
```
````

### Advantages

- **Faster compilation**: No LaTeX→Typst conversion
- **Better error messages**: Typst's errors are clearer
- **More features**: Access to Typst-specific functionality
- **Cleaner syntax**: Less verbose than LaTeX

### Examples

#### Inline

```markdown
The formula `sum_(i=1)^n i` calculates the sum.
```

**Note**: Native Typst inline math syntax requires Typst context (`.typ` files or raw Typst blocks).

#### Display

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

#### Complex

````markdown
```math typst
integral_0^infinity e^(-x^2) dif x
  = sqrt(pi)/2
```
````

### Comparison

| Feature     | LaTeX                           | Typst                |
| ----------- | ------------------------------- | -------------------- |
| Syntax      | `\frac{a}{b}`                   | `a/b`                |
| Subscript   | `x_{ij}`                        | `x_(i j)`            |
| Superscript | `x^{2}`                         | `x^2`                |
| Integral    | `\int_a^b`                      | `integral_a^b`       |
| Sum         | `\sum_{i=1}^n`                  | `sum_(i=1)^n`        |
| Fractions   | `\frac{a}{b}`                   | `a/b` or `frac(a,b)` |
| Matrices    | `\begin{matrix}...\end{matrix}` | `mat(...)`           |

## Migration Guide

### From LaTeX to Typst

If migrating from LaTeX backend:

1. **Keep existing LaTeX math** - It works as-is via mitex
2. **Gradually adopt Typst** - Convert new sections to Typst syntax
3. **Test thoroughly** - Compare PDF output

### Converting Equations

**LaTeX**:

```markdown
`\alpha + \beta = \gamma`
```

**Typst** (in `.typ` context):

```typst
// Using raw string to avoid Julia interpolation in docs
alpha + beta = gamma
```

**LaTeX**:

````markdown
```math
\frac{\partial f}{\partial x} = \lim_{h \to 0} \frac{f(x+h) - f(x)}{h}
```
````

**Typst**:

````markdown
```math typst
(diff f)/(diff x) = lim_(h -> 0) (f(x+h) - f(x))/h
```
````

## Best Practices

### For New Projects

- Use **native Typst math** for better performance and features
- Learn Typst syntax - it's simpler than LaTeX

### For Existing Projects

- Keep **LaTeX math** for compatibility
- Convert incrementally as needed
- Test changes carefully

### Mixed Approach

You can use both in the same document:

````markdown
LaTeX: `\sum_{i=1}^n i`

Typst:

```math typst
sum_(i=1)^n i
```
````

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

**Issue**: Spacing looks wrong

**Solution**:

- LaTeX: Use `\,` `\;` `\quad` for manual spacing
- Typst: Use `space`, `h(1em)`, etc.

## Resources

- [Typst Math Documentation](https://typst.app/docs/reference/math/)
- [mitex Documentation](https://github.com/mitex-rs/mitex)
- [LaTeX to Typst Converter](https://github.com/mitex-rs/mitex)
