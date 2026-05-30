#!/bin/bash
# PIDscope launcher for macOS
# Double-click this file in Finder to launch PIDscope

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

# Set up arch-specific blackbox_decode symlinks
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    ln -sf blackbox_decode.arm64 "$DIR/blackbox_decode"
    ln -sf blackbox_decode_INAV.arm64 "$DIR/blackbox_decode_INAV"
else
    ln -sf blackbox_decode.x86_64 "$DIR/blackbox_decode"
    ln -sf blackbox_decode_INAV.x86_64 "$DIR/blackbox_decode_INAV"
fi

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
    osascript -e 'display dialog "GNU Octave not found.\n\nInstall with:\n  brew install octave\n\nThen install packages:\n  octave --eval \"pkg install -forge datatypes signal statistics control image\"" with title "PIDscope" buttons {"OK"} default button "OK" with icon stop'
    exit 1
fi

# Check and auto-install required Octave Forge packages
PKGMISSING=$("$OCTAVE" --no-gui --eval "for p={'signal','control','image','statistics'}; if isempty(pkg('list',p{1})), fprintf('MISSING\n'); break; end; end" 2>/dev/null)
if echo "$PKGMISSING" | grep -q MISSING; then
    osascript -e 'display notification "Installing required Octave packages (first launch only)..." with title "PIDscope"'
    "$OCTAVE" --no-gui --eval "pkg install -forge datatypes signal statistics control image" 2>&1 | tee /tmp/pidscope-pkg-install.log
    if [ $? -ne 0 ]; then
        osascript -e 'display dialog "Package installation failed.\n\nCheck /tmp/pidscope-pkg-install.log for details.\n\nOr install manually:\n  octave --eval \"pkg install -forge datatypes signal statistics control image\"" with title "PIDscope" buttons {"OK"} default button "OK" with icon stop'
        exit 1
    fi
fi

exec "$OCTAVE" --gui --persist --eval "cd('$DIR'); PIDscope"
