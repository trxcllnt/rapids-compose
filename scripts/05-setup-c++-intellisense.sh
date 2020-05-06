#!/usr/bin/env bash

set -Eeo pipefail

cd $(dirname "$(realpath "$0")")/../../

CODE_REPOS="${CODE_REPOS:-rmm cudf cuml cugraph cuspatial}"

# Setup C++
for REPO in $CODE_REPOS; do
    CPP_DIR="$PWD/$REPO"
    COMPILE_COMMANDS_JSON="compile_commands.json"
    if [ "$REPO" != "rmm" ]; then
        CPP_DIR="$CPP_DIR/cpp"
        COMPILE_COMMANDS_JSON="cpp/$COMPILE_COMMANDS_JSON"
    fi
    # local-ignore .clangd folders
    if [ -z `grep .clangd $PWD/$REPO/.git/info/exclude` ]; then
        echo ".clangd" >> "$PWD/$REPO/.git/info/exclude"
    fi
    # local-ignore the compile_commands.json symlink we're about to create
    if [ -z `grep $COMPILE_COMMANDS_JSON $PWD/$REPO/.git/info/exclude` ]; then
        echo "$COMPILE_COMMANDS_JSON" >> "$PWD/$REPO/.git/info/exclude"
    fi
done

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

install_vscode_extensions() {
    CODE="$1"
    for EXT in ${@:2}; do
        if [ -z "$($CODE --list-extensions | grep $EXT)" ]; then
            ask_before_install \
                "Missing $CODE extension $EXT. Install $EXT now? (y/n)" \
                "$CODE --install-extension $EXT"
        fi
    done
}

for CODE in "code" "code-insiders"; do
    # 1. Install Microsoft C++ Tools if it isn't installed
    # 2. Install vscode-cudacpp if it isn't installed
    # 3. Install vscode-clangd if it isn't installed
    if [ -n "$(which $CODE)" ]; then
        install_vscode_extensions "$CODE" \
            "ms-vscode.cpptools" \
            "xaver.clang-format" \
            "kriegalex.vscode-cudacpp" \
            "augustocdias.tasks-shell-input" \
            "llvm-vs-code-extensions.vscode-clangd";
    fi
done
