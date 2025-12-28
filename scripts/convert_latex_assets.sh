#!/bin/bash
# Convert Julia's LaTeX/TikZ graphics to SVG format
# Usage: ./convert_latex_assets.sh <julia_assets_dir> <output_dir>

set -e

JULIA_ASSETS="$1"  # Path to Julia repo's doc/src/assets
OUTPUT_DIR="$2"     # Output directory

if [ -z "$JULIA_ASSETS" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Usage: $0 <julia_assets_dir> <output_dir>"
    echo "Example: $0 /path/to/julia/doc/src/assets ./assets/typst/julia"
    exit 1
fi

if [ ! -d "$JULIA_ASSETS" ]; then
    echo "Error: Julia assets directory not found: $JULIA_ASSETS"
    exit 1
fi

# Check required dependencies
check_deps() {
    # Check for pdflatex
    if ! command -v pdflatex &> /dev/null; then
        echo "Error: pdflatex not found"
        echo ""
        echo "Install TeX Live:"
        echo "  - macOS:   brew install basictex"
        echo "  - Ubuntu:  apt-get install texlive-latex-base texlive-pictures"
        echo "  - Arch:    pacman -S texlive-core"
        exit 1
    fi
    
    # Check for PDF to SVG converter (prefer pdf2svg, fall back to dvisvgm)
    if command -v pdf2svg &> /dev/null; then
        export PDF_TO_SVG="pdf2svg"
    elif command -v dvisvgm &> /dev/null; then
        export PDF_TO_SVG="dvisvgm"
        echo "Note: Using dvisvgm for PDF->SVG conversion (pdf2svg not found)"
    else
        echo "Error: No PDF to SVG converter found (need pdf2svg or dvisvgm)"
        echo ""
        echo "Install one of them:"
        echo "  - macOS:   brew install pdf2svg  (or use dvisvgm from TeX Live)"
        echo "  - Ubuntu:  apt-get install pdf2svg"
        echo "  - Arch:    pacman -S pdf2svg"
        exit 1
    fi
}

# Convert logo.tex to SVG
convert_logo() {
    echo "Converting Julia logo..."
    
    local temp_dir=$(mktemp -d)
    
    # Create temporary LaTeX document
    cat > "$temp_dir/julia-logo.tex" <<'EOF'
\documentclass[tikz,border=2pt]{standalone}
\usepackage{xcolor}

% Julia brand colors
\definecolor{julia_blue}{RGB}{64,99,216}
\definecolor{julia_red}{RGB}{203,60,51}
\definecolor{julia_purple}{RGB}{149,88,178}
\definecolor{julia_green}{RGB}{56,152,38}

\begin{document}
\newcommand{\scaleFactor}{1}  % Full size output
EOF
    
    # Append logo.tex content (excluding comment lines)
    grep -v "^%" "$JULIA_ASSETS/logo.tex" >> "$temp_dir/julia-logo.tex"
    
    echo '\end{document}' >> "$temp_dir/julia-logo.tex"
    
    # Compile LaTeX to PDF
    cd "$temp_dir"
    pdflatex -interaction=nonstopmode julia-logo.tex > /dev/null 2>&1
    
    if [ ! -f julia-logo.pdf ]; then
        echo "Error: Failed to compile logo.tex"
        cat julia-logo.log
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Convert PDF to SVG
    if [ "$PDF_TO_SVG" = "pdf2svg" ]; then
        pdf2svg julia-logo.pdf "$OUTPUT_DIR/julia-logo.svg"
    else
        # Using dvisvgm
        dvisvgm --pdf julia-logo.pdf --output="$OUTPUT_DIR/julia-logo.svg" --no-fonts 2>/dev/null
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    echo "✓ Logo converted: $OUTPUT_DIR/julia-logo.svg"
}

# Convert splash.tex to SVG
convert_splash() {
    echo "Converting Julia splash pattern..."
    
    local temp_dir=$(mktemp -d)
    
    # Create temporary LaTeX document
    cat > "$temp_dir/julia-splash.tex" <<'EOF'
\documentclass[tikz,border=0pt]{standalone}
\usepackage{xcolor}

% Julia brand colors
\definecolor{julia_blue}{RGB}{64,99,216}
\definecolor{julia_red}{RGB}{203,60,51}
\definecolor{julia_purple}{RGB}{149,88,178}
\definecolor{julia_green}{RGB}{56,152,38}
\definecolor{splash_gary}{RGB}{245,245,245}

\begin{document}
EOF
    
    # Append cover-splash.tex content (excluding comment lines)
    grep -v "^%" "$JULIA_ASSETS/cover-splash.tex" >> "$temp_dir/julia-splash.tex"
    
    echo '\end{document}' >> "$temp_dir/julia-splash.tex"
    
    # Compile LaTeX to PDF
    cd "$temp_dir"
    pdflatex -interaction=nonstopmode julia-splash.tex > /dev/null 2>&1
    
    if [ ! -f julia-splash.pdf ]; then
        echo "Error: Failed to compile cover-splash.tex"
        cat julia-splash.log
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Convert PDF to SVG
    if [ "$PDF_TO_SVG" = "pdf2svg" ]; then
        pdf2svg julia-splash.pdf "$OUTPUT_DIR/julia-splash.svg"
    else
        # Using dvisvgm
        dvisvgm --pdf julia-splash.pdf --output="$OUTPUT_DIR/julia-splash.svg" --no-fonts 2>/dev/null
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
    
    echo "✓ Splash converted: $OUTPUT_DIR/julia-splash.svg"
}

# Main function
main() {
    echo "========================================"
    echo "Julia LaTeX to SVG Converter"
    echo "========================================"
    echo ""
    
    # Convert to absolute path
    OUTPUT_DIR=$(cd "$(dirname "$OUTPUT_DIR")" 2>/dev/null && pwd)/$(basename "$OUTPUT_DIR")
    
    echo "Input:  $JULIA_ASSETS"
    echo "Output: $OUTPUT_DIR"
    echo ""
    
    check_deps
    
    mkdir -p "$OUTPUT_DIR"
    
    convert_logo
    convert_splash
    
    echo ""
    echo "All assets converted successfully!"
    echo "Output directory: $OUTPUT_DIR"
    
    # Show generated file information
    echo ""
    echo "Generated files:"
    for file in "$OUTPUT_DIR"/*.svg; do
        if [ -f "$file" ]; then
            size=$(du -h "$file" | cut -f1)
            echo "  - $(basename "$file") ($size)"
        fi
    done
}

main
