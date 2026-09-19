#!/bin/bash
# Regenerate the macOS AppIcon set from the source art.
# Usage: Tools/make-appicon.sh [source.png]   (default: icon-source.png)
#
# Source art should be a square, full-bleed image with NO squircle mask and
# NO transparent padding — the shape and margin are applied here.
set -euo pipefail
cd "$(dirname "$0")/.."

SRC="${1:-icon-source.png}"
SET="1970/Assets.xcassets/AppIcon.appiconset"
INSET=0.0977   # Apple macOS grid: 824/1024 content area

for s in 16 32 64 128 256 512 1024; do
  swift Tools/squircle.swift "$SRC" "$SET/icon_${s}.png" "$s" "$INSET"
done
echo "Regenerated AppIcon from $SRC into $SET"
