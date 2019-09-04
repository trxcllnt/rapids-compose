#!/usr/bin/env bash

set -e
cd $(dirname "$(realpath "$0")")/../../

ALL_REPOS="${ALL_REPOS:-rmm cugraph custrings cudf
                        notebooks notebooks-extended}"

for REPO in $ALL_REPOS; do
    cd $REPO && git pull upstream $(git branch --show-current) && cd -
done

export GITHUB_USER
