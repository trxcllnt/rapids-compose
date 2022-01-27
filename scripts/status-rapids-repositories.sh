#!/usr/bin/env bash

# Reports on the status of each RAPIDS repository.
#
# By default the short form of the status is reported, along with the branch
# name (`-s -b`) - an alternative form can be reported by providing the
# arguments to `git status` as arguments to this script.

set -Eeo pipefail

if [ ! -z $1 ]
then
    # Use arguments for status from user
    ARGS="$@"
else
    # Default arguments: short-form changes with branch
    ARGS="-s -b"
fi

cd $(dirname "$(realpath "$0")")/../../

BASE_DIR="$(pwd)"

CODE_REPOS="${CODE_REPOS:-rmm raft cudf cuml cugraph cuspatial}"
ALL_REPOS="${ALL_REPOS:-$CODE_REPOS compose notebooks-contrib}"

for REPO in $ALL_REPOS; do
    echo "$REPO:";
    pushd "$BASE_DIR/$REPO";
    git status $ARGS;
    popd;
done
