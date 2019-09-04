#!/usr/bin/env bash

set -e
cd $(dirname "$(realpath "$0")")/../../

for REPO in $ALL_REPOS; do
    # Clone if doesn't exist
    if [ ! -d "$PWD/$REPO" ]; then
        if [ "$GITHUB_USER" = "" ]; then
            read -p "enter your github username: " GITHUB_USER </dev/tty
        fi
        git clone --recurse-submodules git@github.com:$GITHUB_USER/$REPO.git
        cd $REPO && git remote add -f upstream git@github.com:rapidsai/$REPO.git && cd -
    fi
done
