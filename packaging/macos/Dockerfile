# PIDscope macOS packaging (no compilation, binaries come from GH Actions or /cache)
#
# docker build -t pidscope-macos packaging/macos/
# docker run --rm -v $(pwd):/src -v $(pwd)/dist:/dist pidscope-macos

FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    zip wget zstd \
    && rm -rf /var/lib/apt/lists/*

ARG INAV_BB_VERSION=9.0.0

RUN mkdir -p /cache && \
    wget -q "https://github.com/iNavFlight/blackbox-tools/releases/download/v${INAV_BB_VERSION}/blackbox-tools-${INAV_BB_VERSION}_macos-aarch64.tar.zst" \
        -O /tmp/inav-arm64.tar.zst && \
    tar --zstd -xf /tmp/inav-arm64.tar.zst -C /tmp && \
    cp /tmp/bin/blackbox_decode /cache/blackbox_decode_INAV.arm64 && \
    rm -rf /tmp/bin /tmp/share /tmp/inav-arm64.tar.zst && \
    wget -q "https://github.com/iNavFlight/blackbox-tools/releases/download/v${INAV_BB_VERSION}/blackbox-tools-${INAV_BB_VERSION}_macos-x86_64.tar.zst" \
        -O /tmp/inav-x86.tar.zst && \
    tar --zstd -xf /tmp/inav-x86.tar.zst -C /tmp && \
    cp /tmp/bin/blackbox_decode /cache/blackbox_decode_INAV.x86_64 && \
    rm -rf /tmp/bin /tmp/share /tmp/inav-x86.tar.zst

WORKDIR /build
COPY build-macos.sh /build/
RUN chmod +x /build/build-macos.sh
ENTRYPOINT ["/build/build-macos.sh"]
