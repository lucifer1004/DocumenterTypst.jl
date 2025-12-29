# justfile for DocumenterTypst.jl development tasks
# Cross-platform compatible: Windows, Linux, macOS

# Default recipe to display help message
default:
    @just --list

# Run test suite
test:
    julia --project -e 'using Pkg; Pkg.test()'

# Update snapshot test files
test-snapshot-update:
    @echo "Updating all snapshot test files..."
    UPDATE_SNAPSHOTS=1 julia --project=. test/runtests.jl

# Run integration tests
# Platforms: typst (default), native, none
test-integration platform="typst":
    @echo "Running integration tests with platform: {{platform}}"
    julia --project=test/integration -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
    julia --project=test/integration -e 'ENV["TYPST_PLATFORM"]="{{platform}}"; include("test/integration/runtests.jl")'

# Format Julia code with Runic
format:
    julia -e 'using Pkg; Pkg.add("Runic"); using Runic; Runic.main(["--verbose", "--inplace", "."])'
    markdownlint-cli2 --fix "**/*.md"

# Build HTML documentation
docs:
    julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate(); include("docs/make.jl")'

# Build Typst/PDF documentation
# Platforms: typst (default), native, none
docs-typst platform="typst":
    @echo "Building Typst documentation with platform: {{platform}}"
    julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
    julia --project=docs docs/make.jl typst {{platform}}

# Generate changelog for docs
changelog:
    julia --project=docs -e 'using Pkg; Pkg.instantiate(); include("docs/changelog.jl")'

# Clean build artifacts (cross-platform)
clean:
    @echo "Cleaning build artifacts..."
    julia -e 'isdir(joinpath("docs", "build")) && rm(joinpath("docs", "build"), recursive=true, force=true)'
    julia -e 'isdir(joinpath("docs", "build-typst")) && rm(joinpath("docs", "build-typst"), recursive=true, force=true)'
    julia -e 'isdir(joinpath("test", "integration", "builds")) && rm(joinpath("test", "integration", "builds"), recursive=true, force=true)'
    julia -e 'isfile(joinpath("docs", "src", "release-notes.md")) && rm(joinpath("docs", "src", "release-notes.md"))'
    julia -e 'for (root, dirs, files) in walkdir("."); for file in files; if endswith(file, ".jl.cov") || endswith(file, ".jl.mem") || (occursin(".jl.", file) && endswith(file, ".cov")); try rm(joinpath(root, file)); catch; end; end; end; end'

# Install package in dev mode
dev:
    julia --project -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'

# Run tests with coverage (for CI)
ci-test:
    julia --project -e 'using Pkg; Pkg.test(coverage=true)'
