#!/bin/bash
# Build PIDscope macOS ZIP package
# docker build -t pidscope-macos packaging/macos/
# docker run --rm -v $(pwd):/src -v $(pwd)/dist:/dist pidscope-macos

set -euo pipefail

SRC_DIR="${1:-/src}"
DIST_DIR="${2:-/dist}"
# Version: env > VERSION file > git tag > fallback
if [ -n "${PIDSCOPE_VERSION:-}" ]; then
    VERSION="${PIDSCOPE_VERSION}"
elif [ -f "${SRC_DIR}/VERSION" ]; then
    VERSION=$(tr -d '[:space:]' < "${SRC_DIR}/VERSION")
else
    VERSION=$(cd "${SRC_DIR}" && git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "dev")
fi
STAGING="/tmp/PIDscope-${VERSION}-macos"

echo "=== Building PIDscope macOS package v${VERSION} ==="

rm -rf "${STAGING}"
mkdir -p "${STAGING}"

# 1. Copy PIDscope source files
echo "Copying PIDscope files..."
cp "${SRC_DIR}"/PIDscope.m "${STAGING}/"
cp -r "${SRC_DIR}/src" "${STAGING}/"

# 2. Copy blackbox_decode binaries
# BF: from GH Actions artifacts (mounted) or /cache; INAV: from /cache (Dockerfile)
echo "Copying blackbox_decode binaries..."
for bin in blackbox_decode.arm64 blackbox_decode.x86_64 blackbox_decode_INAV.arm64 blackbox_decode_INAV.x86_64; do
    if [ -f "/cache/${bin}" ]; then
        cp "/cache/${bin}" "${STAGING}/"
    elif [ -f "${SRC_DIR}/${bin}" ]; then
        cp "${SRC_DIR}/${bin}" "${STAGING}/"
    else
        echo "WARNING: ${bin} not found, skipping (BF binaries come from GH Actions)"
    fi
done

# 3. Copy launcher
cp "${SRC_DIR}/packaging/macos/pidscope.command" "${STAGING}/"
chmod +x "${STAGING}/pidscope.command"
for bin in "${STAGING}"/blackbox_decode*; do
    [ -f "$bin" ] && chmod +x "$bin"
done

# 4. Copy icon
if [ -f "${SRC_DIR}/packaging/com.pidscope.PIDscope.png" ]; then
    cp "${SRC_DIR}/packaging/com.pidscope.PIDscope.png" "${STAGING}/PIDscope.png"
fi

# 5. Copy VERSION file
if [ -f "${SRC_DIR}/VERSION" ]; then
    cp "${SRC_DIR}/VERSION" "${STAGING}/"
fi

# 6. Create README
cat > "${STAGING}/README-macOS.txt" <<'HEREDOC'
PIDscope - Blackbox Flight Log Analyzer
========================================

FIRST TIME SETUP:
1. Install GNU Octave:
   brew install octave
   (If you don't have Homebrew: https://brew.sh)

2. Remove macOS quarantine - run this in Terminal:
   xattr -cr ~/Downloads/PIDscope-*-macos

3. Launch PIDscope:
   Double-click "pidscope.command"
   (Octave packages are installed automatically on first launch)

ALTERNATIVE (Terminal):
   cd /path/to/PIDscope-folder
   octave --gui --persist --eval "PIDscope"

REQUIREMENTS:
- macOS 12+ (Monterey or later)
- GNU Octave 9.x, 10.x, or 11.x (via Homebrew)
- Apple Silicon (M1/M2/M3/M4/M5) or Intel Mac

Project: https://buymeacoffee.com/dzikus
License: GPL v3
HEREDOC

# 7. Create ZIP
echo "Creating ZIP package..."
mkdir -p "${DIST_DIR}"
cd /tmp
zip -r -q "${DIST_DIR}/PIDscope-${VERSION}-macos-universal.zip" \
    "PIDscope-${VERSION}-macos"

echo "=== macOS package built: ${DIST_DIR}/PIDscope-${VERSION}-macos-universal.zip ==="
ls -lh "${DIST_DIR}/PIDscope-${VERSION}-macos-universal.zip"
