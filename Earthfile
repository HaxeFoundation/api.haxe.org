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
