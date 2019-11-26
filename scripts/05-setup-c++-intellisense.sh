#!/usr/bin/env bash

set -Eeuo pipefail

cd $(dirname "$(realpath "$0")")/../../

find . -type d -name '.clangd' -print0 | xargs -0 -I {} /bin/rm -rf "{}"

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

if [ -n `which code` ]; then
    # Install Microsoft C++ Tools if it isn't installed
    if [ -z `code --list-extensions | grep ms-vscode.cpptools` ]; then
        code --install-extension ms-vscode.cpptools
    fi

    # Install vscode-cudacpp if it isn't installed
    if [ -z `code --list-extensions | grep kriegalex.vscode-cudacpp` ]; then
        code --install-extension kriegalex.vscode-cudacpp
    fi

    # Install vscode-clangd if it isn't installed
    if [ -z `code --list-extensions | grep llvm-vs-code-extensions.vscode-clangd` ]; then
        code --install-extension llvm-vs-code-extensions.vscode-clangd
    fi
fi
