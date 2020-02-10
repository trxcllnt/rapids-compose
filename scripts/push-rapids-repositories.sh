#!/usr/bin/env bash

set -Eeo pipefail

cd $(dirname "$(realpath "$0")")/../../

BASE_DIR="$(pwd)"

CODE_REPOS="${CODE_REPOS:-rmm cudf cuml cugraph}"
ALL_REPOS="${ALL_REPOS:-$CODE_REPOS notebooks notebooks-contrib}"

for REPO in $ALL_REPOS; do
    cd "$BASE_DIR/$REPO" && \
    git push origin $(git branch --show-current) && \
    cd -
done
