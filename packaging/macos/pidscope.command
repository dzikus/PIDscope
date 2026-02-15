#!/bin/bash
# PIDscope launcher for macOS
# Double-click this file in Finder to launch PIDscope

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

# Find Octave
if command -v octave >/dev/null 2>&1; then
    OCTAVE=octave
elif [ -x "/opt/homebrew/bin/octave" ]; then
    OCTAVE=/opt/homebrew/bin/octave
elif [ -x "/usr/local/bin/octave" ]; then
    OCTAVE=/usr/local/bin/octave
elif [ -d "/Applications/Octave-9.2.app" ]; then
    OCTAVE="/Applications/Octave-9.2.app/Contents/Resources/usr/bin/octave"
else
    osascript -e 'display dialog "GNU Octave not found.\n\nInstall with:\n  brew install octave\n\nThen install packages:\n  octave --eval \"pkg install -forge signal statistics control image\"" with title "PIDscope" buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Check if Octave packages are installed (quick check)
if ! "$OCTAVE" --no-gui --eval "pkg load signal" 2>/dev/null; then
    osascript -e 'display dialog "Required Octave packages not found.\n\nRun in Terminal:\n  octave --eval \"pkg install -forge signal statistics control image\"" with title "PIDscope" buttons {"OK"} default button "OK" with icon caution'
    exit 1
fi

exec "$OCTAVE" --gui --persist --eval "cd('$DIR'); PIDscope"
