# Building Julia Documentation with Typst Backend

This directory contains scripts for building Julia's official documentation using the Typst backend, with a custom cover page that matches the LaTeX version.

## Overview

The build process:
1. **Clones** the Julia repository to a temporary directory
2. **Converts** LaTeX assets (logo.tex, cover-splash.tex) to SVG format
3. **Sets up** the Documenter environment
4. **Generates** a custom Typst build script
5. **Compiles** the documentation with Typst backend

## Prerequisites

### Required Tools

- **Git**: For cloning the Julia repository
- **pdflatex**: For compiling TikZ graphics (part of TeX Live)
- **pdf2svg** or **dvisvgm**: For converting PDF to SVG
- **Julia**: Must match the version you want to document

### Installation

**macOS:**
```bash
brew install basictex pdf2svg
# or use dvisvgm from TeX Live (already included)
```

**Ubuntu/Debian:**
```bash
apt-get install texlive-latex-base texlive-pictures pdf2svg
```

**Arch Linux:**
```bash
pacman -S texlive-core pdf2svg
```

## Usage

### Basic Build

Build documentation for the currently installed Julia version (clones to temp directory):

```bash
cd DocumenterTypst
julia scripts/build_julia_docs.jl
```

### Using Existing Julia Repository

If you already have Julia cloned locally, use the `--julia-repo` argument:

```bash
# Using absolute path
julia scripts/build_julia_docs.jl --julia-repo=/path/to/julia

# Using relative path
julia scripts/build_julia_docs.jl --julia-repo=../julia

# Alternative syntax
julia scripts/build_julia_docs.jl --julia-repo ../julia
```

**Benefits:**
- Faster (no cloning needed)
- Useful for development/testing
- Works with custom Julia branches

### With Different Typst Platforms

```bash
# Via command-line argument (preferred)
julia scripts/build_julia_docs.jl --platform=none
julia scripts/build_julia_docs.jl --platform=native
julia scripts/build_julia_docs.jl --platform=typst
julia scripts/build_julia_docs.jl --platform=docker

# Via environment variable (still supported)
TYPST_PLATFORM=native julia scripts/build_julia_docs.jl

# Combine both
julia scripts/build_julia_docs.jl --julia-repo=../julia --platform=none
```

### Show Help

```bash
julia scripts/build_julia_docs.jl --help
```

## Scripts

### `build_julia_docs.jl`

Main build script that orchestrates the entire process.

**Features:**
- Automatic Julia repository cloning (or use existing via `--julia-repo`)
- Version-aware (uses the commit of your Julia binary)
- LaTeX asset conversion
- Documenter environment setup
- Custom cover page integration
- Smart script generation:
  - Reads Julia's original `make.jl`
  - Replaces format definition with `DocumenterTypst.Typst`
  - Adds custom preamble with Julia branding
  - Updates output path from `pdf` to `typst`

**Command-line Arguments:**
- `--julia-repo=PATH` - Use existing Julia repository
- `--platform=PLATFORM` - Typst compilation backend
- `--help` - Show help message

**Output:**
- Location: `<julia_repo>/doc/_build/typst/en/`
- Files: `TheJuliaLanguage.pdf` (or `.typ` if `platform=none`)
- Generated: `make_typst_generated.jl` (temporary build script)

### `convert_latex_assets.sh`

Converts Julia's LaTeX/TikZ graphics to SVG format.

**Usage:**
```bash
bash scripts/convert_latex_assets.sh <julia_assets_dir> <output_dir>

# Example:
bash scripts/convert_latex_assets.sh \
  /path/to/julia/doc/src/assets \
  assets/typst/julia
```

**Converts:**
- `logo.tex` → `julia-logo.svg` (7KB)
- `cover-splash.tex` → `julia-splash.svg` (25KB)

**Requirements:**
- pdflatex
- pdf2svg or dvisvgm

## Assets

### `assets/typst/julia/`

Contains Typst templates and converted graphics:

- **`cover.typ`**: Cover page template with Julia branding
- **`custom.typ`**: Global style configuration
- **`julia-logo.svg`**: Julia logo (converted from TikZ)
- **`julia-splash.svg`**: Background pattern (converted from TikZ)

### Using the Cover Template

```typst
#import "assets/typst/julia/cover.typ": julia_cover

// Render cover page
#julia_cover(
  title: "The Julia Language",
  version: "1.11.0",
  authors: "The Julia Project",
  date: datetime.today()
)
```

## Build Time

Expected compilation time on M4 Max:
- **Platform=none**: ~10 seconds (no PDF compilation)
- **Platform=typst**: ~60-90 seconds (full build with PDF)
- **Platform=native**: ~60-90 seconds (depends on system typst)

## Troubleshooting

### "Missing required commands"

Install the missing tools listed in the Prerequisites section.

### "Failed to compile logo.tex"

Check that you have a working LaTeX installation:
```bash
pdflatex --version
```

### "No PDF files found"

If using `platform=native`, ensure typst is installed:
```bash
typst --version
```

### "Build directory not found"

The build might have failed. Check the Julia build logs:
- `make -C /path/to/julia julia-stdlib`
- `make -C /path/to/julia/doc deps`

## Notes

- **Temporary Directory**: By default, the Julia repository is cloned to a temporary directory and cleaned up after the build
- **Existing Repository**: Use `--julia-repo` to reuse an existing clone (faster for development)
- **No Modification**: Your existing Julia installation is not modified
- **Version Match**: When cloning, the script automatically uses the commit corresponding to your Julia version
- **Asset Generation**: SVG assets are generated once and reused for subsequent builds
- **Generated Script**: Creates `make_typst_generated.jl` in the Julia doc directory (temporary, can be deleted)

## Examples

### Quick Test Build

Generate `.typ` source without PDF compilation (fastest):

```bash
# Clone to temp directory
TYPST_PLATFORM=none julia scripts/build_julia_docs.jl

# Or with existing Julia repo
julia scripts/build_julia_docs.jl --julia-repo=../julia --platform=none
```

### Production Build

Full PDF compilation with Typst_jll:

```bash
julia scripts/build_julia_docs.jl
```

### Development Workflow

When working on documentation changes:

```bash
# 1. Clone Julia once
git clone https://github.com/JuliaLang/julia.git ~/julia

# 2. Make changes to Julia docs
cd ~/julia/doc/src
# ... edit files ...

# 3. Build with Typst (reuse the clone)
cd /path/to/DocumenterTypst
julia scripts/build_julia_docs.jl --julia-repo=~/julia --platform=none

# 4. Check output, iterate
```

### Testing Different Julia Versions

```bash
# Build from specific Julia repository
julia scripts/build_julia_docs.jl --julia-repo=/path/to/julia-1.10

# Build from development branch
julia scripts/build_julia_docs.jl --julia-repo=/path/to/julia-dev
```

## Contributing

When modifying the cover design:

1. Edit `assets/typst/julia/cover.typ`
2. Test with a small document first
3. Verify visual consistency with the LaTeX version

## License

These scripts are part of DocumenterTypst.jl and inherit its MIT license.
