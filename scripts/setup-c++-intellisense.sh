#!/usr/bin/env bash

set -e
cd $(dirname "$(realpath "$0")")/../../

# Setup C++
for REPO in $CODE_REPOS; do
    CPP_DIR="$PWD/$REPO"
    COMPILE_COMMANDS_JSON="compile_commands.json"
    if [ "$REPO" != "rmm" ]; then
        CPP_DIR="$CPP_DIR/cpp"
        COMPILE_COMMANDS_JSON="cpp/$COMPILE_COMMANDS_JSON"
    fi
    # local-ignore the compile_commands.json symlink we're about to create
    if [ -z `grep $COMPILE_COMMANDS_JSON $PWD/$REPO/.git/info/exclude` ]; then
        echo "$COMPILE_COMMANDS_JSON" >> "$PWD/$REPO/.git/info/exclude"
    fi
    # symlink compile_commands.json so vscode-clangd can find it
    mkdir -p "$CPP_DIR/build" && touch "$CPP_DIR/build/compile_commands.json"
    ln -f -n -s "$CPP_DIR/build/compile_commands.json" "$CPP_DIR/compile_commands.json"
done

mkdir -p "$PWD/cudf/java/.vscode"
# Symlink .vscode dir for cudf java bindings
# ln -f -n -s "$PWD/compose/etc/rapids/.vscode" "$PWD/cudf/java/.vscode"

# Install vscode-cudacpp if it isn't installed
if [ -z `code --list-extensions | grep kriegalex.vscode-cudacpp` ]; then
    code --install-extension kriegalex.vscode-cudacpp
fi

# Install vscode-clangd if it isn't installed
if [ -z `code --list-extensions | grep llvm-vs-code-extensions.vscode-clangd` ]; then
    code --install-extension llvm-vs-code-extensions.vscode-clangd
fi
