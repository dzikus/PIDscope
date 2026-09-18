#!/bin/bash
# Build the blackbox_decode binaries into the repo root for local development.
set -euo pipefail

BF_REV="${BF_BLACKBOX_REV:-f832acf9cd9dbe5ad8220de1a5f4eb4021523d72}"
INAV_REV="${INAV_BLACKBOX_REV:-v9.0.0}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

build() {
    local url="$1" rev="$2" out="$3"
    echo "Building ${out} from ${url} @ ${rev}"
    git clone -q "${url}" "${WORK}/src"
    git -C "${WORK}/src" checkout -q --detach "${rev}"
    make -C "${WORK}/src" -j"$(nproc)" obj/blackbox_decode >/dev/null
    cp "${WORK}/src/obj/blackbox_decode" "${ROOT}/${out}"
    chmod +x "${ROOT}/${out}"
    rm -rf "${WORK}/src"
}

build https://github.com/betaflight/blackbox-tools.git "${BF_REV}"  blackbox_decode
build https://github.com/iNavFlight/blackbox-tools.git "${INAV_REV}" blackbox_decode_INAV

echo "Done:"
ls -l "${ROOT}/blackbox_decode" "${ROOT}/blackbox_decode_INAV"
