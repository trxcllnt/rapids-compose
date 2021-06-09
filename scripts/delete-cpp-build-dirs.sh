#!/usr/bin/env bash

set -Eeo pipefail

cd $(dirname "$(realpath "$0")")/../../

BASE_DIR="$(pwd)"

CPP_BUILD_DIRS="rmm/build
                raft/cpp/build
                cudf/cpp/build
                cuml/cpp/build
                cugraph/cpp/build
                cuspatial/cpp/build"

ask_before_del() {
    while true; do
        read -p "$1 (default=$2) " CHOICE </dev/tty
        if [ "$CHOICE" = "" ]; then CHOICE="$2"; fi;
        case $CHOICE in
            [Yy]* ) eval $3; break;;
            [Nn]* ) eval $4; break;;
            * ) echo "Please answer 'y' or 'n'";;
        esac
    done
}

echo "Deleting C++ build directories..."

for DIR in $CPP_BUILD_DIRS; do
    ask_before_del \
        "Remove $BASE_DIR/$DIR (y/n)?" \
        "N" \
        "rm -rf $BASE_DIR/$DIR || true" \
        "echo \"Skipping removing $DIR\""
done
