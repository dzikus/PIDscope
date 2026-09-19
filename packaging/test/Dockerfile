# Unit test environment for PIDscope
# docker build -t pidscope-test packaging/test/
# docker run --rm -v $(pwd):/src -w /src pidscope-test octave --no-gui --eval "run('tests/run_tests.m')"

FROM ubuntu:22.04 AS forge
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:ubuntuhandbook1/octave && \
    apt-get update && \
    apt-get install -y octave octave-dev build-essential libsuitesparse-dev && \
    rm -rf /var/lib/apt/lists/*

RUN octave --eval "\
    pkg install 'https://github.com/gnu-octave/pkg-control/releases/download/control-4.2.1/control-4.2.1.tar.gz'; \
    pkg install 'https://github.com/gnu-octave/octave-signal/releases/download/1.4.7/signal-1.4.7.tar.gz';"


FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:ubuntuhandbook1/octave && \
    apt-get update && \
    apt-get install -y octave libfftw3-3 libopenblas0 libfontconfig1 libfreetype6 && \
    apt-get purge -y software-properties-common && apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

COPY --from=forge /usr/share/octave/packages /usr/share/octave/packages
COPY --from=forge /usr/lib/x86_64-linux-gnu/octave/packages /usr/lib/x86_64-linux-gnu/octave/packages
COPY --from=forge /usr/share/octave/site/api-v61/octave_packages /usr/share/octave/site/api-v61/octave_packages

RUN octave-cli --eval "pkg load signal; pkg load control; disp(version); pkg list"

WORKDIR /src
