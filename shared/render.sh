#!/bin/bash
# Render a resume HTML file to PDF.
#   ./render.sh ../Babylist/resume.html          -> ../Babylist/resume.pdf
#   ./render.sh ../Babylist/resume.html out.pdf  -> out.pdf
set -e
IN="$1"; [ -z "$IN" ] && { echo "usage: render.sh <file.html> [out.pdf]"; exit 1; }
IN="$(cd "$(dirname "$IN")" && pwd)/$(basename "$IN")"
OUT="${2:-${IN%.html}.pdf}"
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf="$OUT" "file://$IN" 2>/dev/null
echo "wrote $OUT"
