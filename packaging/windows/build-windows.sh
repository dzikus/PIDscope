#!/bin/bash
# Build PIDscope Windows ZIP package
# docker build -t pidscope-windows packaging/windows/
# docker run --rm -v $(pwd):/src -v $(pwd)/dist:/dist pidscope-windows

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
STAGING="/tmp/PIDscope-${VERSION}-windows"

echo "=== Building PIDscope Windows package v${VERSION} ==="

rm -rf "${STAGING}"
mkdir -p "${STAGING}/app"

# 1. Extract Octave portable
echo "Extracting Octave portable (this takes a while)..."
cd /tmp
7z x -y /cache/octave-10.3.0-w64.7z -o/tmp/octave-extract > /dev/null
mv /tmp/octave-extract/octave-10.3.0-w64 "${STAGING}/octave"

# 2. Strip unnecessary files to reduce package size
echo "Stripping unnecessary files..."
# Remove toolchains not needed at runtime
rm -rf "${STAGING}/octave/clang64"
rm -rf "${STAGING}/octave/ucrt64"
rm -rf "${STAGING}/octave/notepad++"
rm -rf "${STAGING}/octave/mingw64/include"
# Remove bulky doc files but keep .qhc/.qch (prevents Qt Help startup errors)
find "${STAGING}/octave/mingw64/share/octave/10.3.0/doc" -name '*.html' -delete 2>/dev/null || true
find "${STAGING}/octave/mingw64/share/octave/10.3.0/doc" -name '*.pdf' -delete 2>/dev/null || true
rm -rf "${STAGING}/octave/mingw64/share/doc"
rm -rf "${STAGING}/octave/mingw64/share/info"
rm -rf "${STAGING}/octave/mingw64/share/man"
# Remove .a static libraries (not needed at runtime)
find "${STAGING}/octave/mingw64/lib" -name '*.a' -delete 2>/dev/null || true

# Keep only required Forge packages (signal, statistics, control, image + their deps)
KEEP_PKGS="signal statistics control image io"
for forge_root in \
    "${STAGING}/octave/mingw64/share/octave/packages" \
    "${STAGING}/octave/mingw64/lib/octave/packages"; do
    if [ -d "${forge_root}" ]; then
        for pkg_dir in "${forge_root}"/*/; do
            [ -d "${pkg_dir}" ] || continue
            pkg_name=$(basename "${pkg_dir}" | sed 's/-[0-9].*//')
            keep=0
            for kp in ${KEEP_PKGS}; do
                if [ "${pkg_name}" = "${kp}" ]; then keep=1; break; fi
            done
            if [ ${keep} -eq 0 ]; then
                echo "  Removing forge package: ${pkg_name}"
                rm -rf "${pkg_dir}"
            fi
        done
    fi
done

echo "Octave size after stripping:"
du -sh "${STAGING}/octave"

# 3. Copy PIDscope source files
echo "Copying PIDscope files..."
cp "${SRC_DIR}"/PIDscope.m "${STAGING}/app/"
cp "${SRC_DIR}"/VERSION "${STAGING}/app/"
cp -r "${SRC_DIR}/src" "${STAGING}/app/"

# 4. Copy blackbox_decode binaries (cross-compiled)
cp /cache/blackbox_decode.exe "${STAGING}/app/"
cp /cache/blackbox_decode_INAV.exe "${STAGING}/app/"

# 5. Suppress Windows Terminal false-positive warning (only affects CLI, not GUI)
OCTAVERC="${STAGING}/octave/mingw64/share/octave/site/m/startup/octaverc"
if [ -f "${OCTAVERC}" ]; then
    echo "% PIDscope: site octaverc cleared (Windows Terminal warning is false positive in GUI mode)" > "${OCTAVERC}"
fi

# 6. Copy launcher and icon
cp "${SRC_DIR}/packaging/windows/PIDscope.bat" "${STAGING}/"
if [ -f "${SRC_DIR}/packaging/com.pidscope.PIDscope.png" ]; then
    cp "${SRC_DIR}/packaging/com.pidscope.PIDscope.png" "${STAGING}/PIDscope.png"
fi

# 6. Create ZIP
echo "Creating ZIP package..."
mkdir -p "${DIST_DIR}"
cd /tmp
zip -r -q "${DIST_DIR}/PIDscope-${VERSION}-windows-x86_64.zip" \
    "PIDscope-${VERSION}-windows"

echo "=== Windows package built: ${DIST_DIR}/PIDscope-${VERSION}-windows-x86_64.zip ==="
ls -lh "${DIST_DIR}/PIDscope-${VERSION}-windows-x86_64.zip"
