#!/usr/bin/env bash

set -Eeo pipefail

cd $(dirname "$(realpath "$0")")/../../

BASE_DIR="$(pwd)"

CODE_REPOS="${CODE_REPOS:-rmm raft cudf cuml cugraph cuspatial}"
ALL_REPOS="${ALL_REPOS:-$CODE_REPOS notebooks-contrib}"

COMMON_BRANCHES=""

echo "Determining available branches."
for REPO in $CODE_REPOS; do
    echo "$REPO ..."
    cd "$BASE_DIR/$REPO";
    git fetch --no-tags upstream;
    REMOTE_BRANCHES="";
    for x in $(git branch -r | grep upstream); do
        REMOTE_BRANCHES="${REMOTE_BRANCHES:+$REMOTE_BRANCHES\n}${x#upstream/}";
    done
    if [ -z "$COMMON_BRANCHES" ]; then
        COMMON_BRANCHES="$(echo -e "$REMOTE_BRANCHES" | sort -V)";
    else
        COMMON_BRANCHES="$(echo -e "$COMMON_BRANCHES\n$REMOTE_BRANCHES" | sort -V | uniq -d)";
    fi
    cd - >/dev/null 2>&1;
done

COMMON_BRANCHES="$(echo -e "$COMMON_BRANCHES" | grep -v master | sort -Vr)";

echo "Please select a branch to check out:"

BRANCHES=(${COMMON_BRANCHES});
BRANCH_NAME=""

select BRANCH_NAME in "${BRANCHES[@]}" "Quit"; do
    if [[ $REPLY -lt $(( ${#BRANCHES[@]}+1 )) ]]; then
        break;
    elif [[ $REPLY -eq $(( ${#BRANCHES[@]}+1 )) ]]; then
        exit 0;
    else
        echo "Invalid option, please select a branch (or quit)"
    fi
done;

echo "Starting checkout."
for REPO in $CODE_REPOS; do
    echo "----- $REPO/$BRANCH_NAME -----"
    cd "$BASE_DIR/$REPO";
    git checkout "$BRANCH_NAME";
    git submodule update --init --recursive;
    cd - >/dev/null 2>&1;
done
