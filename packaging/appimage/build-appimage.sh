#!/bin/bash
# Build PIDscope AppImage
# docker build -t pidscope-appimage packaging/appimage/
# docker run --rm -v $(pwd):/src -v $(pwd)/dist:/dist pidscope-appimage

set -euo pipefail

SRC_DIR="${1:-/src}"
DIST_DIR="${2:-/dist}"
APPDIR="/tmp/PIDscope.AppDir"
VERSION="0.58"

echo "=== Building PIDscope AppImage v${VERSION} ==="

rm -rf "${APPDIR}"
mkdir -p "${APPDIR}"/usr/{bin,lib} \
         "${APPDIR}"/usr/share/{pidscope,applications,metainfo,mime/packages,icons/hicolor/256x256/apps}

# Source files
cp "${SRC_DIR}"/*.m "${APPDIR}/usr/share/pidscope/"
cp -r "${SRC_DIR}/compat" "${APPDIR}/usr/share/pidscope/"

for decoder in blackbox_decode blackbox_decode_INAV; do
    if [ -f "${SRC_DIR}/${decoder}" ]; then
        cp "${SRC_DIR}/${decoder}" "${APPDIR}/usr/share/pidscope/"
        chmod +x "${APPDIR}/usr/share/pidscope/${decoder}"
    else
        echo "WARNING: ${decoder} not found in ${SRC_DIR}"
    fi
done

# Desktop integration
cp "${SRC_DIR}/packaging/pidscope.desktop" "${APPDIR}/usr/share/applications/"
cp "${SRC_DIR}/packaging/pidscope.desktop" "${APPDIR}/pidscope.desktop"
cp "${SRC_DIR}/packaging/com.pidscope.PIDscope.appdata.xml" "${APPDIR}/usr/share/metainfo/"
cp "${SRC_DIR}/packaging/com.pidscope.PIDscope.mime.xml" "${APPDIR}/usr/share/mime/packages/"

# Icon
cp "${SRC_DIR}/packaging/com.pidscope.PIDscope.png" "${APPDIR}/usr/share/icons/hicolor/256x256/apps/"
ln -sf usr/share/icons/hicolor/256x256/apps/com.pidscope.PIDscope.png "${APPDIR}/com.pidscope.PIDscope.png"
cp "${APPDIR}/usr/share/icons/hicolor/256x256/apps/com.pidscope.PIDscope.png" "${APPDIR}/.DirIcon"

cp "${SRC_DIR}/packaging/appimage/AppRun" "${APPDIR}/AppRun"
chmod +x "${APPDIR}/AppRun"

# Octave runtime
echo "Bundling Octave..."

for bin in octave octave-cli; do
    p=$(which ${bin} 2>/dev/null || true)
    [ -n "${p}" ] && cp "$(readlink -f "${p}")" "${APPDIR}/usr/bin/${bin}" && chmod +x "${APPDIR}/usr/bin/${bin}"
done

# libexec (octave-gui, octave-svgconvert)
OCTAVE_LIBEXECDIR=$(octave-config -p LIBEXECDIR 2>/dev/null || echo "/usr/libexec")
if [ -d "${OCTAVE_LIBEXECDIR}/octave" ]; then
    mkdir -p "${APPDIR}${OCTAVE_LIBEXECDIR}"
    cp -r "${OCTAVE_LIBEXECDIR}/octave" "${APPDIR}${OCTAVE_LIBEXECDIR}/"
fi

OCTAVE_LIB_DIR=$(octave-config -p OCTLIBDIR 2>/dev/null || echo "/usr/lib/x86_64-linux-gnu/octave")
[ -d "${OCTAVE_LIB_DIR}" ] && cp -r "${OCTAVE_LIB_DIR}" "${APPDIR}/usr/lib/" 2>/dev/null || true

OCTAVE_DATA=$(octave-config -p DATADIR 2>/dev/null || echo "/usr/share")
if [ -d "${OCTAVE_DATA}/octave" ]; then
    cp -r "${OCTAVE_DATA}/octave" "${APPDIR}/usr/share/" 2>/dev/null || true
fi

# Qt plugins
QT_PLUGIN_SRC="/usr/lib/x86_64-linux-gnu/qt5/plugins"
if [ -d "${QT_PLUGIN_SRC}" ]; then
    mkdir -p "${APPDIR}/usr/lib/qt5/plugins"
    for plug in platforms imageformats platforminputcontexts xcbglintegrations sqldrivers; do
        [ -d "${QT_PLUGIN_SRC}/${plug}" ] && cp -r "${QT_PLUGIN_SRC}/${plug}" "${APPDIR}/usr/lib/qt5/plugins/"
    done
fi

# Forge packages
for pkgdir in /usr/share/octave/packages /usr/lib/x86_64-linux-gnu/octave/packages; do
    if [ -d "${pkgdir}" ]; then
        mkdir -p "${APPDIR}${pkgdir}"
        cp -r "${pkgdir}"/* "${APPDIR}${pkgdir}/" 2>/dev/null || true
    fi
done

# linuxdeploy (extract -- no FUSE in Docker)
echo "Bundling shared libraries..."
cd /tmp
rm -rf linuxdeploy-squashfs
mkdir linuxdeploy-squashfs && cd linuxdeploy-squashfs
/usr/local/bin/linuxdeploy --appimage-extract 2>/dev/null || true
cd /tmp

LINUXDEPLOY="/tmp/linuxdeploy-squashfs/squashfs-root/AppRun"
if [ -x "${LINUXDEPLOY}" ]; then
    "${LINUXDEPLOY}" \
        --appdir "${APPDIR}" \
        --desktop-file "${APPDIR}/pidscope.desktop" \
        --icon-file "${APPDIR}/usr/share/icons/hicolor/256x256/apps/com.pidscope.PIDscope.png" \
        --library /usr/lib/x86_64-linux-gnu/libfftw3.so.3 \
        --library /usr/lib/x86_64-linux-gnu/libopenblas.so.0 \
        2>&1 || echo "linuxdeploy completed (some warnings expected)"
else
    echo "WARNING: linuxdeploy extraction failed, skipping library bundling"
fi

# appimagetool
echo "Creating AppImage..."
mkdir -p "${DIST_DIR}"

cd /tmp
rm -rf appimagetool-squashfs
mkdir appimagetool-squashfs && cd appimagetool-squashfs
/usr/local/bin/appimagetool --appimage-extract 2>/dev/null || true
cd /tmp

APPIMAGETOOL="/tmp/appimagetool-squashfs/squashfs-root/AppRun"
if [ -x "${APPIMAGETOOL}" ]; then
    ARCH=x86_64 "${APPIMAGETOOL}" "${APPDIR}" "${DIST_DIR}/PIDscope-${VERSION}-x86_64.AppImage"
else
    echo "ERROR: appimagetool extraction failed."
    exit 1
fi

echo "=== AppImage built: ${DIST_DIR}/PIDscope-${VERSION}-x86_64.AppImage ==="
ls -lh "${DIST_DIR}/PIDscope-${VERSION}-x86_64.AppImage"
