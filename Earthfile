VERSION 0.6
FROM ubuntu:jammy
WORKDIR /workspace

haxe-src:
    ARG --required TAG
    GIT CLONE --branch "$TAG" https://github.com/HaxeFoundation/haxe.git haxe
    SAVE ARTIFACT haxe

info.json:
    FROM buildpack-deps:scm
    ARG --required TAG
    COPY (+haxe-src/haxe --TAG="$TAG") /src
    WORKDIR /src
    RUN echo "{\"commit\":\"$(git rev-parse HEAD)\",\"branch\":\"$TAG\"}" > info.json
    SAVE ARTIFACT info.json

xml-4.3.0:
    FROM haxe:4.3.0
    COPY (+haxe-src/haxe --TAG=4.3.0) /src
    WORKDIR /src/extra
    RUN haxelib newrepo
    RUN haxelib git hxcpp  https://github.com/HaxeFoundation/hxcpp  v4.3.7
    RUN haxelib git hxjava https://github.com/HaxeFoundation/hxjava 3.1.0
    RUN haxelib git hxcs   https://github.com/HaxeFoundation/hxcs   v3.1.0
    RUN haxe doc.hxml
    COPY (+info.json/info.json --TAG=4.3.0) doc/info.json
    SAVE ARTIFACT --keep-ts doc AS LOCAL ./xml/4.3.0

xml-4.3.1:
    FROM haxe:4.3.1
    COPY (+haxe-src/haxe --TAG=4.3.1) /src
    WORKDIR /src/extra
    RUN haxelib newrepo
    RUN haxelib git hxcpp  https://github.com/HaxeFoundation/hxcpp  v4.3.7
    RUN haxelib git hxjava https://github.com/HaxeFoundation/hxjava 3.1.0
    RUN haxelib git hxcs   https://github.com/HaxeFoundation/hxcs   v3.1.0
    RUN haxe doc.hxml
    COPY (+info.json/info.json --TAG=4.3.1) doc/info.json
    SAVE ARTIFACT --keep-ts doc AS LOCAL ./xml/4.3.1

neko-latest:
    FROM curlimages/curl:8.00.1
    WORKDIR /tmp
    ARG TARGETARCH
    ARG FILENAME=neko_latest.tar.gz
    RUN haxeArch=$(case "$TARGETARCH" in \
        amd64) echo "linux64";; \
        arm64) echo "linux-arm64";; \
    esac); curl -fsSLO "https://build.haxe.org/builds/neko/$haxeArch/$FILENAME"
    RUN mkdir -p neko
    RUN tar --strip-components=1 -xf "$FILENAME" -C neko
    SAVE ARTIFACT neko/*

haxe-latest:
    FROM curlimages/curl:8.00.1
    WORKDIR /tmp
    ARG TARGETARCH
    ARG FILENAME=haxe_latest.tar.gz
    RUN haxeArch=$(case "$TARGETARCH" in \
        amd64) echo "linux64";; \
        arm64) echo "linux-arm64";; \
    esac); curl -fsSLO "https://build.haxe.org/builds/haxe/$haxeArch/$FILENAME"
    RUN mkdir -p haxe
    RUN tar --strip-components=1 -xf "$FILENAME" -C haxe
    SAVE ARTIFACT haxe/*

build-env:
    RUN apt-get update \
        && apt-get install -qqy --no-install-recommends \
            ca-certificates \
        # Clean up
        && apt-get autoremove -y \
        && apt-get clean -y \
        && rm -rf /var/lib/apt/lists/*

    # install neko
    COPY +neko-latest/neko /usr/bin/neko
    COPY +neko-latest/libneko.so* /usr/lib/
    RUN mkdir -p /usr/lib/neko/
    COPY +neko-latest/*.ndll /usr/lib/neko/
    RUN neko -version

    # install haxe
    COPY +haxe-latest/haxe /usr/bin/haxe
    COPY +haxe-latest/haxelib /usr/bin/haxelib
    RUN mkdir -p /usr/share/haxe/
    COPY +haxe-latest/std /usr/share/haxe/std
    RUN haxe --version

    RUN haxelib newrepo

gen.n:
    FROM +build-env
    COPY gen.hxml .
    RUN haxelib install all --always
    COPY *.hx .
    RUN haxe gen.hxml
    SAVE ARTIFACT gen.n

hxcpp:
    FROM +build-env
    GIT CLONE https://github.com/HaxeFoundation/hxcpp.git hxcpp
    RUN cd hxcpp/tools/hxcpp && haxe compile.hxml
    SAVE ARTIFACT hxcpp

dox-cpp:
    FROM +build-env

    RUN apt-get update \
        && apt-get install -qqy --no-install-recommends \
            g++ \
        # Clean up
        && apt-get autoremove -y \
        && apt-get clean -y \
        && rm -rf /var/lib/apt/lists/*

    COPY libs libs
    RUN haxelib dev hxparse libs/hxparse
    RUN haxelib dev hxtemplo libs/hxtemplo
    RUN haxelib dev hxargs libs/hxargs
    RUN haxelib dev markdown libs/haxe-markdown
    RUN haxelib dev dox libs/dox
    COPY +hxcpp/hxcpp hxcpp
    RUN haxelib dev hxcpp hxcpp
    RUN haxelib list
    COPY dox.hxml .
    RUN haxe dox.hxml
    SAVE ARTIFACT libs/dox/cpp/Dox

html:
    FROM +build-env
    COPY libs libs
    COPY theme theme
    COPY xml xml
    COPY +dox-cpp/Dox libs/dox/cpp/Dox
    COPY +gen.n/gen.n .
    RUN neko gen.n
    SAVE ARTIFACT --keep-ts html AS LOCAL ./html

validate-html:
    FROM ghcr.io/validator/validator:23.4.11
    COPY html html
    # validate only the top level html files for now since there are many errors in e.g. js/html/*.html
    RUN vnu --errors-only html/*.html

deploy:
    FROM haxe:$HAXE_VERSION
    WORKDIR /workspace
    RUN apt-get update \
        && apt-get install -qqy --no-install-recommends \
            awscli \
        # Clean up
        && apt-get autoremove -y \
        && apt-get clean -y \
        && rm -rf /var/lib/apt/lists/*
    COPY --keep-ts +generate/out out
    COPY src src
    COPY downloads downloads
    COPY deploy.hxml .
    RUN --no-cache ls -lah
    RUN --no-cache \
        --mount=type=secret,id=+secrets/.envrc,target=.envrc \
        . ./.envrc \
        && haxe deploy.hxml
