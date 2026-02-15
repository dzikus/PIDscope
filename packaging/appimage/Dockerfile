# PIDscope AppImage build environment
# docker build -t pidscope-appimage packaging/appimage/
# docker run --rm -v $(pwd):/src -v $(pwd)/dist:/dist pidscope-appimage

FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Latest Octave from PPA (Ubuntu 22.04 repos only have 6.x)
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:ubuntuhandbook1/octave && \
    apt-get update

RUN apt-get install -y \
    octave liboctave-dev \
    build-essential git \
    wget file desktop-file-utils appstream \
    libfftw3-3 libopenblas0 libsuitesparse-dev \
    libgl1-mesa-glx libfontconfig1 libfreetype6 \
    && rm -rf /var/lib/apt/lists/*

RUN octave --eval "\
    pkg install -forge control; \
    pkg install -forge signal; \
    pkg install -forge datatypes; \
    pkg install -forge statistics; \
    pkg install -forge image;"

# Compile blackbox_decode from source (not in git)
RUN mkdir -p /cache && \
    git clone --depth=1 https://github.com/betaflight/blackbox-tools.git /tmp/bb-bf && \
    cd /tmp/bb-bf && make -j$(nproc) obj/blackbox_decode && \
    gcc -o /cache/blackbox_decode obj/*.o -lm && \
    cd / && rm -rf /tmp/bb-bf && \
    git clone --depth=1 https://github.com/iNavFlight/blackbox-tools.git /tmp/bb-inav && \
    cd /tmp/bb-inav && make -j$(nproc) obj/blackbox_decode && \
    cp obj/blackbox_decode /cache/blackbox_decode_INAV && \
    cd / && rm -rf /tmp/bb-inav

RUN wget -q "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage" \
        -O /usr/local/bin/linuxdeploy && \
    chmod +x /usr/local/bin/linuxdeploy && \
    wget -q "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" \
        -O /usr/local/bin/appimagetool && \
    chmod +x /usr/local/bin/appimagetool

WORKDIR /build
COPY build-appimage.sh /build/
RUN chmod +x /build/build-appimage.sh
ENTRYPOINT ["/build/build-appimage.sh"]
