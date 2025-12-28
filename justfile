# justfile for DocumenterTypst.jl development tasks
# Cross-platform compatible: Windows, Linux, macOS

# Default recipe to display help message
default:
    @just --list

# Run test suite
test:
    julia --project -e 'using Pkg; Pkg.test()'

# Format code with Runic
format:
    julia -e 'using Pkg; Pkg.add("Runic"); using Runic; Runic.main(["--verbose", "--inplace", "."])'

# Build HTML documentation
docs:
    julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); include("docs/make.jl")'

# Build Typst/PDF documentation
docs-typst:
    julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
    julia --project=docs docs/make.jl typst

# Build Typst/PDF documentation with native compilation
docs-typst-native:
    julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
    julia --project=docs docs/make.jl typst native

# Build Typst source without compilation
docs-typst-source:
    julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
    julia --project=docs docs/make.jl typst none

# Generate changelog for docs
changelog:
    julia --project=docs -e 'using Pkg; Pkg.instantiate(); include("docs/changelog.jl")'

# Clean build artifacts (cross-platform)
clean:
    @echo "Cleaning build artifacts..."
    julia -e 'isdir(joinpath("docs", "build")) && rm(joinpath("docs", "build"), recursive=true, force=true)'
    julia -e 'isdir(joinpath("docs", "build-typst")) && rm(joinpath("docs", "build-typst"), recursive=true, force=true)'
    julia -e 'isfile(joinpath("docs", "src", "release-notes.md")) && rm(joinpath("docs", "src", "release-notes.md"))'
    julia -e 'for (root, dirs, files) in walkdir("."); for file in files; if endswith(file, ".jl.cov") || endswith(file, ".jl.mem") || (occursin(".jl.", file) && endswith(file, ".cov")); try rm(joinpath(root, file)); catch; end; end; end; end'

# Install package in dev mode
dev:
    julia --project -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'

# Run tests with coverage (for CI)
ci-test:
    julia --project -e 'using Pkg; Pkg.test(coverage=true)'
