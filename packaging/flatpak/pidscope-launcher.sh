#!/bin/bash
# pidscope-launcher.sh - Flatpak wrapper for PIDscope
# Installed to /app/bin/pidscope

PTB_DIR="/app/share/pidscope"

# Ensure config directory exists
mkdir -p "${HOME}/.config/PIDscope"

exec octave \
    --gui \
    --persist \
    --eval "cd('${PTB_DIR}'); addpath('${PTB_DIR}'); addpath('${PTB_DIR}/compat'); PIDscope"
