#!/usr/bin/env bash

set -e
set -o errexit

cpp-build-type() {
    echo "${CMAKE_BUILD_TYPE:-Release}" | tr '[:upper:]' '[:lower:]'
}

export -f cpp-build-type;

cpp-build-dir() {
    cd "$1"
    _BUILD_DIR="$(git branch --show-current)"
    echo "build/b-${_BUILD_DIR//\//__}/$(cpp-build-type)"
}

export -f cpp-build-dir;

make-symlink() {
    SRC="$1"; DST="$2";
    CUR=$(readlink "$2" || echo "");
    [ "$CUR" = "$SRC" ] \
     || ln -f -n -s "$SRC" "$DST"
}

export -f make-symlink;
