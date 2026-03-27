FROM rustlang/rust:nightly

LABEL org.opencontainers.image.source="https://github.com/tektronix/tsp-toolkit-build"
LABEL org.opencontainers.image.description="The docker container definition used to build Keithley TSP Toolkit"
LABEL org.opencontainers.image.licenses="MIT"

ENV NODE_VERSION 24.14.1

# Shamelessly stolen from
#   https://github.com/nodejs/docker-node/blob/4e0fff70002f51c2b121c9b231917abcb63d2b1a/16/buster/Dockerfile
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
        amd64) ARCH='x64';; \
        ppc64el) ARCH='ppc64le';; \
        s390x) ARCH='s390x';; \
        arm64) ARCH='arm64';; \
        armhf) ARCH='armv7l';; \
        i386) ARCH='x86';; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    # gpg keys in for-loop below listed at https://github.com/nodejs/node#release-keys
    && set -ex \
    && for key in \
        5BE8A3F6C8A5C01D106C0AD820B1A390B168D356 \
        DD792F5973C6DE52C432CBDAC77ABFA00DDBF2B7 \
        CC68F5A3106FF448322E48ED27F5E38D5B0A215F \
        8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
        890C08DB8579162FEE0DF9DB8BEAB4DFCF555EF4 \
        C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
        108F52B48DB57BB0CC439B2997B01419BD92F80A \
        A363A499291CBBC940DD62E41F10027AF002F8B0 \
    ; do \
        gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
        gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
    done \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
    # smoke tests
    && node --version \
    && npm --version \
    && apt-get update \
    && apt-get install -yqq \
        pkg-config \
        libssl-dev \
        mingw-w64 \
        ninja-build \
        clamav \
        jq \
        python3 \
        python3-pip \
        libdbus-1-dev \
    && rustup target add x86_64-pc-windows-gnu \
    && rustup component add \
        llvm-tools-preview \
        rustfmt \
        clippy \
        cargo \
    && cargo install \
        cargo2junit \
        grcov \
        cargo-cyclonedx \
        cargo-llvm-cov \
        cargo-nextest
