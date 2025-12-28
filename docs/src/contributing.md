# Contributing to DocumenterTypst.jl

Thank you for your interest in contributing to DocumenterTypst.jl!

## Code of Conduct

This project follows the [Julia Community Standards](https://julialang.org/community/standards/).

## Getting Started

### Setting Up Your Development Environment

1. **Fork and clone the repository**:

   ```bash
   git clone https://github.com/YOUR_USERNAME/DocumenterTypst.jl.git
   cd DocumenterTypst.jl
   ```

2. **Install dependencies**:

   ```julia
   using Pkg
   Pkg.activate(".")
   Pkg.instantiate()
   ```

3. **Run tests**:
   ```julia
   Pkg.test()
   ```

## Making Changes

### Workflow

1. Create a new branch for your changes:

   ```bash
   git checkout -b your-feature-branch
   ```

2. Make your changes and commit them with clear messages:

   ```bash
   git commit -m "Add feature X"
   ```

3. Push to your fork and create a pull request:
   ```bash
   git push origin your-feature-branch
   ```

### Code Style

We use [Runic.jl](https://github.com/fredrikekre/Runic.jl) for Julia code formatting.

**Format your code before committing**:

```julia
using Pkg
Pkg.add("Runic")
using Runic
Runic.main(["--verbose", "."])
```

Or use the justfile:

```bash
just format
```

CI will check formatting automatically using Runic v1.2.

## Testing

### Running Tests

```julia
using Pkg
Pkg.test("DocumenterTypst")
```

### Adding Tests

When adding new features:

1. Add unit tests to `test/runtests.jl`
2. Test both success and error cases
3. Ensure tests are fast (use `platform="none"` to skip compilation)

Example:

```julia
@testset "New Feature" begin
    output = render_to_typst("**new syntax**")
    @test contains(output, "expected output")
end
```

### Test Coverage

We aim for 90%+ code coverage. Check coverage locally:

```julia
using Pkg
Pkg.test("DocumenterTypst"; coverage=true)
```

## Documentation

### Building Documentation Locally

```bash
julia --project=docs -e '
  using Pkg
  Pkg.develop(PackageSpec(path=pwd()))
  Pkg.instantiate()
  include("docs/make.jl")
'
```

Output will be in `docs/build/`.

### Documentation Style

- Use clear, concise language
- Provide code examples
- Include "See also" links
- Test all code examples

## Changelog

**All user-visible changes must have a changelog entry.**

### Adding a Changelog Entry

Edit `CHANGELOG.md` under the "Unreleased" section:

```markdown
## Unreleased

### Added

- New feature description. ([#123])

### Fixed

- Bug fix description. ([#124])
```

### Categories

- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

### Linking Issues/PRs

Reference issues and PRs using `([#123])` notation. The link will be auto-generated.

### Skip Changelog

For trivial changes (typo fixes, CI tweaks), add the `Skip Changelog` label to your PR.

## Pull Request Guidelines

### Before Submitting

- [ ] Code is formatted (`just format` or Runic.jl)
- [ ] Tests pass locally (`Pkg.test()`)
- [ ] Typst backend tests pass (if applicable)
- [ ] Spell check passes (`typos`)
- [ ] Changelog updated (if needed)
- [ ] Documentation updated (if adding features)
- [ ] Commit messages are clear

### CI Checks

Your PR will be automatically checked for:

- ✅ Julia code formatting (Runic)
- ✅ Spell checking (Typos)
- ✅ File formatting (Prettier)
- ✅ Changelog update
- ✅ Tests on Linux/macOS/Windows
- ✅ Typst backend tests
- ✅ Documentation build
- ✅ Link checking
- ✅ Code coverage

All checks must pass before merging.

### PR Description

Include:

- **What**: What does this PR do?
- **Why**: Why is this change needed?
- **How**: How does it work?
- **Testing**: How was it tested?

Example:

```markdown
## What

Adds support for custom fonts in Typst output.

## Why

Users want to match their organization's branding.

## How

- Adds `fonts` parameter to `Typst` constructor
- Passes `--font-path` to Typst compiler
- Updates documentation and tests

## Testing

- Added unit tests for font path generation
- Tested with custom font on Linux/macOS/Windows
- Updated docs with example

Closes #42
```

### Review Process

1. Automated CI checks must pass
2. At least one maintainer approval required
3. No unresolved review comments
4. Up-to-date with main branch

## Issue Guidelines

### Before Opening an Issue

1. **Search existing issues** - Your issue may already exist
2. **Check documentation** - The answer might be there
3. **Try latest version** - The bug might be fixed

### Bug Reports

Include:

- **Summary**: Brief description
- **Steps to reproduce**: Minimal reproducible example
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Environment**:
  ```
  Julia version:
  DocumenterTypst version:
  OS:
  ```
- **Minimal example**: Complete code to reproduce

### Feature Requests

Include:

- **Use case**: Why is this needed?
- **Proposed solution**: How should it work?
- **Alternatives considered**: Other approaches?
- **Examples**: Code examples of desired API

## Development Tips

### Quick Iteration

For fast development cycles:

```julia
using DocumenterTypst

makedocs(
    format = DocumenterTypst.Typst(platform = "none"),
    doctest = false,
)
```

Then compile manually:

```bash
cd docs/build
typst compile Package.typ
```

### Debugging

Enable debug output:

```bash
export DOCUMENTER_TYPST_DEBUG="debug-output"
export DOCUMENTER_VERBOSE="true"
julia docs/make.jl
```

Check generated files in `debug-output/`.

### Testing Against Documenter Main

Test compatibility with Documenter development version:

```julia
using Pkg
Pkg.add(name="Documenter", rev="main")
Pkg.test("DocumenterTypst")
```

## Release Process

(For maintainers)

1. Update `CHANGELOG.md`:
   - Move "Unreleased" to "Version [vX.Y.Z] - YYYY-MM-DD"
   - Add version comparison link
   - Create new "Unreleased" section

2. Update `Project.toml` version

3. Commit and tag:

   ```bash
   git commit -am "Release vX.Y.Z"
   git tag vX.Y.Z
   git push origin main --tags
   ```

4. Register with JuliaRegistrator:

   ```
   @JuliaRegistrator register
   ```

5. GitHub Actions will automatically:
   - Run full test suite
   - Build documentation
   - Create GitHub release

## Getting Help

- **Questions**: Open a [Discussion](https://github.com/lucifer1004/DocumenterTypst.jl/discussions)
- **Bugs**: Open an [Issue](https://github.com/lucifer1004/DocumenterTypst.jl/issues)
- **Chat**: Join [Julia Slack](https://julialang.org/slack/) #documentation channel

## Recognition

Contributors will be:

- Listed in release notes
- Acknowledged in documentation
- Added to `.zenodo.json` (if substantial contribution)

Thank you for contributing! 🎉
