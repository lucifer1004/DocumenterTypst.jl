# justfile for DocumenterTypst.jl development tasks
# Cross-platform compatible: Windows, Linux, macOS

# Show available commands
default:
    @just --list

# ============================================================================
# Code Quality
# ============================================================================

[unix]
[group("quality")]
pre-commit:
    @if command -v prek > /dev/null 2>&1; then prek run --all-files; else pre-commit run --all-files; fi

[windows]
[group("quality")]
pre-commit:
    @where prek >nul 2>&1 && prek run --all-files || pre-commit run --all-files

# Check Markdown formatting
[group("quality")]
lint-md-check:
    markdownlint-cli2 "**/*.md"
alias mc := lint-md-check

# Fix Markdown formatting
[group("quality")]
lint-md:
    markdownlint-cli2 --fix "**/*.md"
alias mw := lint-md

# Format Julia code with Runic
[group("quality")]
format-julia:
    julia -e 'using Pkg; Pkg.add("Runic"); using Runic; Runic.main(["--verbose", "--inplace", "."])'
alias fj := format-julia

# Format Julia and Markdown files
[group("quality")]
format:
    @just format-julia
    @just lint-md
alias fmt := format

# ============================================================================
# Testing Commands
# ============================================================================

# Run unit tests only
[group("testing")]
test-unit:
    julia --project=. test/run_unit_tests.jl
alias tu := test-unit

# Run integration tests
[arg("platform", pattern="^(typst|native|none)$")]
[group("testing")]
test-integration platform="typst":
    @echo "Running integration tests with platform: {{ platform }}"
    julia --project=test/integration -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
    julia --project=test/integration -e 'ENV["TYPST_PLATFORM"]="{{ platform }}"; include("test/integration/runtests.jl")'
alias ti := test-integration

# Run snapshot tests
[group("testing")]
test-snapshot:
    julia --project=. test/run_snapshot_tests.jl
alias ts := test-snapshot

# Run all tests locally (unit + integration + snapshot)
[group("testing")]
test:
    @just test-unit
    @just test-integration typst
    @just test-snapshot
alias t := test

# Run full test suite like CI (unit + all integration platforms + snapshot)
[group("testing")]
test-ci:
    @just test-unit
    @just test-integration typst
    @just test-integration native
    @just test-integration none
    @just test-snapshot
alias tc := test-ci

# Update text snapshots only (fast)
[group("testing")]
test-snapshot-update-text:
    julia --project=. -e 'ENV["UPDATE_SNAPSHOTS"]="1"; ENV["SKIP_VISUAL_SNAPSHOTS"]="1"; include("test/run_snapshot_tests.jl")'

# Update visual snapshots only (slow, requires integration fixtures)
[group("testing")]
test-snapshot-update-visual:
    julia --project=. -e 'ENV["UPDATE_SNAPSHOTS"]="1"; ENV["SKIP_TEXT_SNAPSHOTS"]="1"; include("test/run_snapshot_tests.jl")'

# Update all snapshots (text + visual)
[group("testing")]
test-snapshot-update:
    julia --project=. -e 'ENV["UPDATE_SNAPSHOTS"]="1"; include("test/run_snapshot_tests.jl")'

# ============================================================================
# Documentation
# ============================================================================

# Build HTML documentation
[group("docs")]
docs:
    julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate(); include("docs/make.jl")'
alias d := docs

# Build Typst/PDF documentation
[arg("platform", pattern="^(typst|native|none)$")]
[group("docs")]
docs-typst platform="typst":
    @echo "Building Typst documentation with platform: {{ platform }}"
    julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
    julia --project=docs docs/make.jl typst {{ platform }}
alias dt := docs-typst

# Generate changelog for docs
[group("docs")]
changelog:
    julia --project=docs docs/changelog.jl
    markdownlint-cli2 --fix CHANGELOG.md
alias cl := changelog

# ============================================================================
# Development
# ============================================================================

# Install package in dev mode
[group("development")]
dev:
    julia --project -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'

# Clean build artifacts (cross-platform)
[group("development")]
clean:
    @echo "Cleaning build artifacts..."
    julia -e 'isdir(joinpath("docs", "build")) && rm(joinpath("docs", "build"), recursive=true, force=true)'
    julia -e 'isdir(joinpath("docs", "build-typst")) && rm(joinpath("docs", "build-typst"), recursive=true, force=true)'
    julia -e 'isdir(joinpath("test", "integration", "builds")) && rm(joinpath("test", "integration", "builds"), recursive=true, force=true)'
    julia -e 'isdir(joinpath("test", "snapshots", "visual", "failures")) && rm(joinpath("test", "snapshots", "visual", "failures"), recursive=true, force=true)'
    julia -e 'isfile(joinpath("docs", "src", "release-notes.md")) && rm(joinpath("docs", "src", "release-notes.md"))'
    julia -e 'for (root, dirs, files) in walkdir("."); for file in files; if endswith(file, ".jl.cov") || endswith(file, ".jl.mem") || (occursin(".jl.", file) && endswith(file, ".cov")); try rm(joinpath(root, file)); catch; end; end; end; end'
