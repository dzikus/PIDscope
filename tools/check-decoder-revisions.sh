#!/bin/bash
# Fail if the pinned blackbox-tools revisions drift apart between packaging
# paths and THIRD-PARTY-LICENSES.md.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

fail=0

check() {
    local label="$1"; shift
    local found
    found=$(printf '%s\n' "$@" | sort -u)
    if [ "$(printf '%s\n' "${found}" | wc -l)" -ne 1 ]; then
        echo "MISMATCH: ${label} is pinned to more than one revision:"
        printf '  %s\n' ${found}
        fail=1
    else
        echo "OK: ${label} = ${found}"
    fi
}

bf_win=$(grep -oP 'ARG BF_BLACKBOX_REV=\K\S+'   packaging/windows/Dockerfile)
bf_app=$(grep -oP 'ARG BF_BLACKBOX_REV=\K\S+'   packaging/appimage/Dockerfile)
bf_rel=$(grep -oP 'BF_BLACKBOX_REV: \K\S+'      .github/workflows/release.yml)
bf_fpk=$(grep -A5 'name: blackbox-decode-bf'    packaging/flatpak/com.pidscope.PIDscope.yml | grep -oP 'commit: \K\S+')
bf_dev=$(grep -oP 'BF_REV="\$\{BF_BLACKBOX_REV:-\K[^}]+'   tools/fetch-decoders.sh)
bf_doc=$(grep -oP '^\| Revision built \| `\K[0-9a-f]{40}'   THIRD-PARTY-LICENSES.md)

check "betaflight/blackbox-tools" "$bf_win" "$bf_app" "$bf_rel" "$bf_fpk" "$bf_dev" "$bf_doc"

inav_win=$(grep -oP 'ARG INAV_BLACKBOX_REV=\K\S+' packaging/windows/Dockerfile)
inav_app=$(grep -oP 'ARG INAV_BLACKBOX_REV=\K\S+' packaging/appimage/Dockerfile)
inav_fpk=$(grep -A5 'name: blackbox-decode-inav'  packaging/flatpak/com.pidscope.PIDscope.yml | grep -oP 'tag: \K\S+')
inav_dev=$(grep -oP 'INAV_REV="\$\{INAV_BLACKBOX_REV:-\K[^}]+' tools/fetch-decoders.sh)
inav_mac=$(grep -oP 'ARG INAV_BB_VERSION=\K\S+'   packaging/macos/Dockerfile | sed 's/^/v/')
inav_rel=$(grep -oP 'INAV_BB_VERSION: "\K[^"]+'   .github/workflows/release.yml | sed 's/^/v/')

check "iNavFlight/blackbox-tools" "$inav_win" "$inav_app" "$inav_fpk" "$inav_dev" "$inav_mac" "$inav_rel"

exit "${fail}"
