#!/usr/bin/env bash

set -Eeo pipefail

cd $(dirname "$(realpath "$0")")/../../

BASE_DIR="$(pwd)"

CODE_REPOS="${CODE_REPOS:-rmm raft cudf cuml cugraph cuspatial}"
ALL_REPOS="${ALL_REPOS:-$CODE_REPOS notebooks-contrib}"

for REPO in $ALL_REPOS; do
    cd "$BASE_DIR/$REPO";
    BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD)";
    while [ -z "$(git branch -r | grep upstream/$BRANCH_NAME)" ]; do
        UPSTREAM_INFO="$(git remote -v show | grep upstream | head -n1)";
        read -p "
############################################################
Branch \"$BRANCH_NAME\" not found in:
${UPSTREAM_INFO}
############################################################

Please enter a branch name to merge (or leave empty to skip): " BRANCH_NAME </dev/tty
    done
    if [ -n "$BRANCH_NAME" ]; then
        git merge upstream/"$BRANCH_NAME";
        git submodule update --init --recursive;
    else
        echo -e "No alternate branch name supplied, skipping\n";
    fi;
    cd - >/dev/null 2>&1;
done
