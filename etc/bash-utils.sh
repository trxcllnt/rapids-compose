#!/usr/bin/env bash

set -Eeuo pipefail

find-project-home() {
    PROJECT_HOMES="\
    $RMM_HOME
    $CUDF_HOME
    $CUGRAPH_HOME
    $NOTEBOOKS_HOME
    $NOTEBOOKS_EXTENDED_HOME";
    for PROJECT_HOME in $PROJECT_HOMES; do
        if [ -n "$(echo "$PWD" | grep "$PROJECT_HOME" - || echo "")" ]; then
            echo "$PROJECT_HOME"; break;
        fi;
    done
}

export -f find-project-home;

find-cpp-build-home() {
    echo "$(find-project-home)/cpp/build/$(cpp-build-type)";
}

export -f find-cpp-build-home;

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

update-environment-variables() {
    set -a && . "$COMPOSE_HOME/.env" && set +a
    bash $CONDA_PREFIX/etc/conda/activate.d/env-vars.sh
    unset NVIDIA_VISIBLE_DEVICES
}

export -f update-environment-variables;
