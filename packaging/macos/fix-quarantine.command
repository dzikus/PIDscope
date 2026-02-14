#!/bin/bash
# Remove macOS quarantine flags from PIDscope files
# Double-click this file in Finder after downloading PIDscope

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Removing quarantine flags from PIDscope..."
xattr -r -d com.apple.quarantine "$DIR" 2>/dev/null
chmod +x "$DIR/blackbox_decode" "$DIR/blackbox_decode_INAV" "$DIR/pidscope.command" 2>/dev/null

echo ""
echo "Done! You can now launch PIDscope by double-clicking pidscope.command"
echo ""
read -p "Press Enter to close..."
