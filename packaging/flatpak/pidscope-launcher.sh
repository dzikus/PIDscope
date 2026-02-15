#!/bin/bash
# pidscope-launcher.sh - Flatpak wrapper for PIDscope
# Installed to /app/bin/pidscope

PS_DIR="/app/share/pidscope"

# Ensure config directory exists
mkdir -p "${HOME}/.config/PIDscope"

exec octave \
    --gui \
    --persist \
    --eval "cd('${PS_DIR}'); PIDscope"
