# PIDscope Windows build environment
# docker build -t pidscope-windows packaging/windows/
# docker run --rm -v $(pwd):/src -v $(pwd)/dist:/dist pidscope-windows

FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    p7zip-full zip wget git curl make \
    gcc-mingw-w64-x86-64 \
    && rm -rf /var/lib/apt/lists/*

# Pre-download Octave portable (cached in Docker image layer)
# Use ftpmirror (ftp.gnu.org is unreliable/blocked from some networks)
RUN mkdir -p /cache && \
    wget -q --show-progress "https://ftpmirror.gnu.org/gnu/octave/windows/octave-10.3.0-w64.7z" \
        -O /cache/octave-10.3.0-w64.7z

# Cross-compile blackbox_decode.exe from betaflight and iNav
# BIN_DIR = obj/, so output is obj/blackbox_decode
RUN git clone --depth=1 https://github.com/betaflight/blackbox-tools.git /tmp/blackbox-tools-bf && \
    cd /tmp/blackbox-tools-bf && \
    CC=x86_64-w64-mingw32-gcc make -j$(nproc) obj/blackbox_decode && \
    x86_64-w64-mingw32-gcc -o /cache/blackbox_decode.exe obj/*.o -lm -lws2_32 && \
    rm -rf /tmp/blackbox-tools-bf

RUN git clone --depth=1 https://github.com/iNavFlight/blackbox-tools.git /tmp/blackbox-tools-inav && \
    cd /tmp/blackbox-tools-inav && \
    CC=x86_64-w64-mingw32-gcc make -j$(nproc) obj/blackbox_decode && \
    x86_64-w64-mingw32-gcc -o /cache/blackbox_decode_INAV.exe obj/*.o -lm -lws2_32 && \
    rm -rf /tmp/blackbox-tools-inav

WORKDIR /build
COPY build-windows.sh /build/
RUN chmod +x /build/build-windows.sh
ENTRYPOINT ["/build/build-windows.sh"]
