# justfile for DocumenterTypst.jl development tasks
# Cross-platform compatible: Windows, Linux, macOS

# Default recipe to display help message
default:
    @just --list

# ============================================================================
# Testing Commands
# ============================================================================

# Run unit tests only
test-unit:
    julia --project=. test/run_unit_tests.jl

# Run integration tests
test-integration platform="typst":
    @echo "Running integration tests with platform: {{platform}}"
    julia --project=test/integration -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
    julia --project=test/integration -e 'ENV["TYPST_PLATFORM"]="{{platform}}"; include("test/integration/runtests.jl")'

# Run snapshot tests
test-snapshot:
    julia --project=. test/run_snapshot_tests.jl

# Run all tests locally (unit + integration + snapshot)
test:
    @just test-unit
    @just test-integration typst
    @just test-snapshot

# Run full test suite like CI (unit + all integration platforms + snapshot)
test-ci:
    @just test-unit
    @just test-integration typst
    @just test-integration native
    @just test-integration none
    @just test-snapshot

# Update text snapshots only (fast)
test-snapshot-update-text:
    julia --project=. -e 'ENV["UPDATE_SNAPSHOTS"]="1"; ENV["SKIP_VISUAL_SNAPSHOTS"]="1"; include("test/run_snapshot_tests.jl")'

# Update visual snapshots only (slow, requires integration fixtures)
test-snapshot-update-visual:
    julia --project=. -e 'ENV["UPDATE_SNAPSHOTS"]="1"; ENV["SKIP_TEXT_SNAPSHOTS"]="1"; include("test/run_snapshot_tests.jl")'

# Update all snapshots (text + visual)
test-snapshot-update:
    julia --project=. -e 'ENV["UPDATE_SNAPSHOTS"]="1"; include("test/run_snapshot_tests.jl")'

# ============================================================================
# Code Quality
# ============================================================================

# Format Julia code with Runic
format:
    julia -e 'using Pkg; Pkg.add("Runic"); using Runic; Runic.main(["--verbose", "--inplace", "."])'
    markdownlint-cli2 --fix "**/*.md"

# ============================================================================
# Documentation
# ============================================================================

# Build HTML documentation
docs:
    julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate(); include("docs/make.jl")'

# Build Typst/PDF documentation
docs-typst platform="typst":
    @echo "Building Typst documentation with platform: {{platform}}"
    julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
    julia --project=docs docs/make.jl typst {{platform}}

# Generate changelog for docs
changelog:
    julia --project=docs -e 'using Pkg; Pkg.instantiate(); include("docs/changelog.jl")'

# ============================================================================
# Development
# ============================================================================

# Install package in dev mode
dev:
    julia --project -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'

# Clean build artifacts (cross-platform)
clean:
    @echo "Cleaning build artifacts..."
    julia -e 'isdir(joinpath("docs", "build")) && rm(joinpath("docs", "build"), recursive=true, force=true)'
    julia -e 'isdir(joinpath("docs", "build-typst")) && rm(joinpath("docs", "build-typst"), recursive=true, force=true)'
    julia -e 'isdir(joinpath("test", "integration", "builds")) && rm(joinpath("test", "integration", "builds"), recursive=true, force=true)'
    julia -e 'isdir(joinpath("test", "snapshots", "visual", "failures")) && rm(joinpath("test", "snapshots", "visual", "failures"), recursive=true, force=true)'
    julia -e 'isfile(joinpath("docs", "src", "release-notes.md")) && rm(joinpath("docs", "src", "release-notes.md"))'
    julia -e 'for (root, dirs, files) in walkdir("."); for file in files; if endswith(file, ".jl.cov") || endswith(file, ".jl.mem") || (occursin(".jl.", file) && endswith(file, ".cov")); try rm(joinpath(root, file)); catch; end; end; end; end'
