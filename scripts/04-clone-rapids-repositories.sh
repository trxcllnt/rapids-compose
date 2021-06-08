#!/usr/bin/env bash

set -Eeo pipefail

COMPOSE_HOME=$(dirname $(realpath "$0"))
COMPOSE_HOME=$(realpath "$COMPOSE_HOME/../")
RAPIDS_HOME=$(realpath "$COMPOSE_HOME/../")

cd "$RAPIDS_HOME"

USE_SSH_URLS=1

CODE_REPOS="${CODE_REPOS:-rmm raft cudf cuml cugraph cuspatial}"
ALL_REPOS="${ALL_REPOS:-$CODE_REPOS notebooks-contrib}"

ask_before_install() {
    while true; do
        read -p "$1 " CHOICE </dev/tty
        case $CHOICE in
            [Nn]* ) break;;
            [Yy]* ) eval $2; break;;
            * ) echo "Please answer 'y' or 'n'";;
        esac
    done
}

read_github_username() {
    read -p "Please enter your github username (default: rapidsai) " GITHUB_USER </dev/tty
    if [ "$GITHUB_USER" = "" ]; then
        GITHUB_USER="rapidsai";
    fi
}

read_git_remote_url_ssh_preference() {
    while true; do
        read -p "Use SSH in Github remote URLs (y/n)? " SSH_CHOICE </dev/tty
        case $SSH_CHOICE in
            [Yy]* ) USE_SSH_URLS=1; break;;
            [Nn]* ) USE_SSH_URLS=0; break;;
            * ) echo "Please answer 'y' or 'n'";;
        esac
    done
}

install_github_cli() {
    GITHUB_VERSION=$(curl -s https://api.github.com/repos/github/hub/releases/latest | jq -r ".tag_name" | tr -d 'v')
    # If Github's API is rate-limiting our IP, use a known good Github CLI version
    if [ "$GITHUB_VERSION" = "null" ]; then
        GITHUB_VERSION="2.14.1"
    fi
    echo "Installing github-cli v$GITHUB_VERSION (https://github.com/github/hub)"
    curl -o ./hub-linux-amd64-${GITHUB_VERSION}.tgz \
        -L https://github.com/github/hub/releases/download/v${GITHUB_VERSION}/hub-linux-amd64-${GITHUB_VERSION}.tgz
    tar -xvzf hub-linux-amd64-${GITHUB_VERSION}.tgz
    sudo ./hub-linux-amd64-${GITHUB_VERSION}/install
    sudo mv ./hub-linux-amd64-${GITHUB_VERSION}/etc/hub.bash_completion.sh /etc/bash_completion.d/hub
    rm -rf ./hub-linux-amd64-${GITHUB_VERSION} hub-linux-amd64-${GITHUB_VERSION}.tgz
}

clone_repo() {
    REPO="$1"
    git clone --no-tags -c checkout.defaultRemote=upstream -j $(nproc) \
        --recurse-submodules https://github.com/rapidsai/$REPO.git
}

fork_repo() {
    REPO="$1"
    if [[ "$(which hub)" == "" ]]; then
        # Install github cli if it isn't installed
        ask_before_install "Github CLI not detected. Install Github CLI (y/n)?" "install_github_cli"
    fi
    if [[ "$(which hub)" != "" ]]; then
        echo "Forking rapidsai/$REPO to $GITHUB_USER/$REPO";
        # Clone the rapidsai fork first
        clone_repo "$REPO";
        cd "$REPO";
        hub fork --remote-name=origin;
        cd - >/dev/null 2>&1;
    fi
}

clone_or_fork_repo() {
    REPO="$1"
    HAS_FORK="NO"

    # Clone and/or fork the repo
    if [ "$GITHUB_USER" == "rapidsai" ]; then
        # If default user, clone the rapidsai fork
        clone_repo "$REPO";
    else
        REPO_RESPONSE_CODE="$(curl -I https://github.com/$GITHUB_USER/$REPO 2>/dev/null | head -n 1 | cut -d$' ' -f2)"
        if [ "$REPO_RESPONSE_CODE" = "403" ] || [ "$REPO_RESPONSE_CODE" = "200" ]; then
            HAS_FORK="YES";
            # Clone the rapidsai fork first
            clone_repo "$REPO";
        else
            # If the user doesn't have a fork of this repo yet, offer to fork it now
            ask_before_install "github.com/$GITHUB_USER/$REPO not found. Fork it now (y/n)?" "fork_repo $REPO"
            # If they declined to fork or to install the github cli, clone the rapidsai fork
            if [ ! -d "$RAPIDS_HOME/$REPO" ]; then
                clone_repo "$REPO";
            else
                HAS_FORK="YES";
            fi
        fi
    fi

    # Now fix the remote URLs
    cd "$REPO"
    if [ -z "$(git remote show | grep upstream)" ]; then
        # Always add an "upstream" remote that points to rapidsai
        if [[ "$USE_SSH_URLS" == "1" ]]; then
            git remote add -f --tags upstream git@github.com:rapidsai/$REPO.git
        else
            git remote add -f --tags upstream https://github.com/rapidsai/$REPO.git
        fi
    fi
    if [[ "$HAS_FORK" == "YES" ]]; then
        # If using the user's fork, rewrite the origin URL to point to it
        if [[ "$USE_SSH_URLS" == "1" ]]; then
            git remote set-url origin git@github.com:$GITHUB_USER/$REPO.git
        else
            git remote set-url origin https://github.com/$GITHUB_USER/$REPO.git
        fi
    else
        # If not using a user fork, still add an origin, but make it read-only
        if [[ "$USE_SSH_URLS" == "1" ]]; then
            git remote set-url origin git@github.com:rapidsai/$REPO.git
        else
            git remote set-url origin https://github.com/rapidsai/$REPO.git
        fi
        git remote set-url --push origin read_only
    fi
    git remote set-url --push upstream read_only
    cd - >/dev/null 2>&1
}

CLONED_SOMETHING="NO"

for REPO in $ALL_REPOS; do
    # Clone if doesn't exist
    if [ ! -d "$RAPIDS_HOME/$REPO" ]; then
        if [ "$GITHUB_USER" = "" ]; then
            read_github_username;
            read_git_remote_url_ssh_preference;
        fi
        clone_or_fork_repo $REPO
        CLONED_SOMETHING="YES"
    fi
done

if [[ "$CLONED_SOMETHING" == "YES" ]]; then
    bash -i "$COMPOSE_HOME/scripts/git-checkout-same-branch.sh"
    bash -i "$COMPOSE_HOME/scripts/pull-rapids-repositories.sh"
fi
