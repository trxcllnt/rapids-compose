#!/usr/bin/env bash

set -Eeo pipefail

cd $(dirname "$(realpath "$0")")/../../

BASE_DIR="$(pwd)"

CODE_REPOS="${CODE_REPOS:-rmm raft cudf cuml cugraph cuspatial}"
ALL_REPOS="${ALL_REPOS:-$CODE_REPOS notebooks-contrib}"

for REPO in $ALL_REPOS; do
    echo "Pushing $REPO..."
    cd "$BASE_DIR/$REPO";
    git push origin $(git rev-parse --abbrev-ref HEAD);
    cd - >/dev/null 2>&1;
done
