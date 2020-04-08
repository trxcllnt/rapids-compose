#!/usr/bin/env bash

set -Eeo pipefail

source /home/rapids/.bashrc

# Create or remove ccache compiler symlinks
set-gcc-version $GCC_VERSION >/dev/null 2>&1;

# - ensure conda's installed
# - ensure the rapids conda env is created/updated/activated
source "$COMPOSE_HOME/etc/conda-install.sh" rapids

# activate the rapids conda environment on bash login
echo "source /home/rapids/.bashrc && source activate rapids" > /home/rapids/.bash_login

# Maybe build a local fork of LLVM that treats .cuh files as CUDA headers
LLVM_REPO="$COMPOSE_HOME/etc/llvm";

ask_before_install() {
    while true; do
        read -p "$1 (default: $2): " CHOICE </dev/tty
        if [ "$CHOICE" = "" ]; then
            CHOICE="$2";
        fi
        case $CHOICE in
            [Nn]* ) eval $4; break;;
            [Yy]* ) eval $3; break;;
            * ) echo "Please answer 'y' or 'n'";;
        esac
    done
}

build_local_llvm_fork() {
    ORIG_DIR="$(pwd)";
    (
        set -Eeo pipefail;
        rm -rf "$LLVM_REPO";
        # Clone the LLVM fork with the `.cuh` fix
        git clone \
            --depth 1 --recurse-submodules --branch fix/cuda-headers \
            https://github.com/trxcllnt/llvm-project.git "$LLVM_REPO"
        # delete .git dir to save space
        rm -rf "$LLVM_REPO/.git"
        # Configure and build clang + clang-tools-extra
        mkdir -p "$LLVM_REPO/build" && cd "$LLVM_REPO/build"
        cmake -GNinja \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
            -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra" ../llvm
        cmake --build . -- clang clangd
        # Symlink the LLVM compile_commands.json
        ln -s build/compile_commands.json ../compile_commands.json
        # Print message to update vscode workspace with new clangd path
        echo "Clangd built successfully!"
        echo "Now set \"clangd.path\": \"$LLVM_REPO/build/bin/clangd\" in your VSCode workspace settings."
        # Update vscode workspace with new clangd path
        # find "$RAPIDS_HOME" -maxdepth 1 -type f -name '*.code-workspace' | xargs -I{} sed -i "s@/usr/bin/clangd@$LLVM_REPO/build/bin/clangd@g" {}
    ) || (rm -rf "$LLVM_REPO" && echo "failed to build clangd, exiting")
    # Clean up
    cd "$ORIG_DIR"
}

if [ ! -d "$LLVM_REPO" ]; then
    mkdir -p "$LLVM_REPO"
    ask_before_install "
The current version of LLVM doesn't recognize \`.cuh\` files as CUDA headers. This causes VSCode intellisense activation to fail for \`.cuh\` files.

I can clone and build a fork of LLVM to fix VSCode intellisense for \`.cuh\` files. This will be a one-time cost, and use approx. 2.1 GiB of disk space.

* If you accept, the project will be cloned and built in \"$LLVM_REPO\"
* If you decline, an empty directory will be created for \"$LLVM_REPO\", and no further action will be taken.

You won't see this prompt again unless you delete the directory at \"$LLVM_REPO\"

Would you like to clone and build a local copy of LLVM now (y/n)?" \
    "N" \
    "build_local_llvm_fork" \
    "echo -e \"\\nOk, skipping local llvm-project build.\\n\\nIf you change your mind, you can delete the directory at:\\n
\\\"$LLVM_REPO\\\"\\nand this prompt will appear again on the next container restart.\\n\""
fi;

# If fresh conda env and cmd is build-rapids,
# do `clean-rapids` to delete build artifacts
[ "$FRESH_CONDA_ENV" == "1" ] \
 && [ "$(echo $@)" == "bash -c build-rapids" ] \
 && clean-rapids;

RUN_CMD="$(echo $(eval "echo $@"))"

# Run with gosu because `docker-compose up` doesn't support the --user flag.
# see: https://github.com/docker/compose/issues/1532
if [ "$_UID:$_GID" != "$(id -u):$(id -g)" ]; then
    RUN_CMD="/usr/local/sbin/gosu $_UID:$_GID $RUN_CMD"
fi;

exec -l ${RUN_CMD}
