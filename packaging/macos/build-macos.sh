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

# 2. Copy blackbox_decode universal binaries
echo "Copying blackbox_decode binaries..."
cp /cache/blackbox_decode "${STAGING}/"
cp /cache/blackbox_decode_INAV "${STAGING}/"

# 3. Copy launcher and helper scripts
cp "${SRC_DIR}/packaging/macos/pidscope.command" "${STAGING}/"
cp "${SRC_DIR}/packaging/macos/fix-quarantine.command" "${STAGING}/"
chmod +x "${STAGING}/pidscope.command" "${STAGING}/fix-quarantine.command"
chmod +x "${STAGING}/blackbox_decode" "${STAGING}/blackbox_decode_INAV"

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

2. Install required Octave packages (first time only):
   octave --eval "pkg install -forge signal statistics control image"

3. Remove macOS quarantine (required after download):
   Double-click "fix-quarantine.command"
   (or run in Terminal: xattr -cr /path/to/PIDscope-folder)

4. Launch PIDscope:
   Double-click "pidscope.command"

ALTERNATIVE (Terminal):
   cd /path/to/PIDscope-folder
   octave --gui --persist --eval "PIDscope"

REQUIREMENTS:
- macOS 12+ (Monterey or later)
- GNU Octave 9.x or 10.x (via Homebrew)
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
