#!/bin/bash
# pidscope-launcher.sh - Flatpak wrapper for PIDscope
# Installed to /app/bin/pidscope

PS_DIR="/app/share/pidscope"

# Ensure config directory exists
mkdir -p "${HOME}/.config/PIDscope"

# NOTE: Octave 10.x uigetfile in Flatpak returns wrong directory paths when
# navigating subdirectories. PSuigetfile.m detects /.flatpak-info and uses
# zenity --file-selection instead (zenity is available in the KDE SDK runtime).

exec octave \
    --gui \
    --persist \
    --eval "cd('${PS_DIR}'); PIDscope"
