# PIDscope macOS build environment
# Cross-compiles blackbox_decode as universal binary (arm64 + x86_64)
# using zig cc (no Apple SDK required).
#
# docker build -t pidscope-macos packaging/macos/
# docker run --rm -v $(pwd):/src -v $(pwd)/dist:/dist pidscope-macos

FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    zip wget git make xz-utils llvm \
    && rm -rf /var/lib/apt/lists/*

# Install zig (for macOS cross-compilation without Apple SDK)
RUN wget -q "https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz" \
        -O /tmp/zig.tar.xz && \
    tar -xf /tmp/zig.tar.xz -C /opt && \
    rm /tmp/zig.tar.xz
ENV PATH="/opt/zig-linux-x86_64-0.13.0:${PATH}"

# Cross-compile blackbox_decode for macOS arm64 + x86_64
# Betaflight
RUN git clone --depth=1 https://github.com/betaflight/blackbox-tools.git /tmp/bb-bf && \
    cd /tmp/bb-bf && \
    mkdir -p /cache && \
    CC="zig cc -target aarch64-macos" make -j$(nproc) obj/blackbox_decode && \
    zig cc -target aarch64-macos -o /cache/blackbox_decode.arm64 obj/*.o -lc -lm && \
    make clean && \
    CC="zig cc -target x86_64-macos" make -j$(nproc) obj/blackbox_decode && \
    zig cc -target x86_64-macos -o /cache/blackbox_decode.x86_64 obj/*.o -lc -lm && \
    llvm-lipo-14 -create /cache/blackbox_decode.arm64 /cache/blackbox_decode.x86_64 \
        -output /cache/blackbox_decode && \
    rm -f /cache/blackbox_decode.arm64 /cache/blackbox_decode.x86_64 && \
    rm -rf /tmp/bb-bf

# iNav (LTO_FLAGS= and LDFLAGS= disable -flto which zig cc doesn't support for cross-targets)
RUN git clone --depth=1 https://github.com/iNavFlight/blackbox-tools.git /tmp/bb-inav && \
    cd /tmp/bb-inav && \
    CC="zig cc -target aarch64-macos" make -j$(nproc) LTO_FLAGS= LDFLAGS="-lm" obj/blackbox_decode && \
    cp obj/blackbox_decode /cache/blackbox_decode_INAV.arm64 && \
    make clean && \
    CC="zig cc -target x86_64-macos" make -j$(nproc) LTO_FLAGS= LDFLAGS="-lm" obj/blackbox_decode && \
    cp obj/blackbox_decode /cache/blackbox_decode_INAV.x86_64 && \
    llvm-lipo-14 -create /cache/blackbox_decode_INAV.arm64 /cache/blackbox_decode_INAV.x86_64 \
        -output /cache/blackbox_decode_INAV && \
    rm -f /cache/blackbox_decode_INAV.arm64 /cache/blackbox_decode_INAV.x86_64 && \
    rm -rf /tmp/bb-inav

WORKDIR /build
COPY build-macos.sh /build/
RUN chmod +x /build/build-macos.sh
ENTRYPOINT ["/build/build-macos.sh"]
