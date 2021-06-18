#!/usr/bin/env bash

set -Eeo pipefail

cd $(dirname "$(realpath "$0")")/../../

CODE_REPOS="${CODE_REPOS:-rmm raft cudf cuml cugraph cuspatial}"

# Setup C++
for REPO in $CODE_REPOS; do
    # local-ignore .clangd folders
    if [ -z `grep .clangd $PWD/$REPO/.git/info/exclude` ]; then
        echo ".clangd" >> "$PWD/$REPO/.git/info/exclude"
    fi
    # local-ignore **/compile_commands.json symlinks
    COMPILE_COMMANDS_JSON="**/compile_commands.json"
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

for CODE in code code-insiders; do
    if [ "$(which $CODE)" != "" ]; then
        install_vscode_extensions "$CODE" \
            "twxs.cmake" \
            "ms-vscode.cpptools" \
            "xaver.clang-format" \
            "cschlosser.doxdocgen" \
            "kriegalex.vscode-cudacpp" \
            "augustocdias.tasks-shell-input" \
            "dotiful.dotfiles-syntax-highlighting" \
            "llvm-vs-code-extensions.vscode-clangd";
    fi
done
