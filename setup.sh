#!/usr/bin/env bash

set -e
cd $(dirname "$(realpath "$0")")/../
PWD="$(pwd)"

export GITHUB_USER=""
export vGCC=$(gcc -dumpversion | cut -f1 -d.)
export vGXX=$(g++ -dumpversion | cut -f1 -d.)
export CODE_REPOS="rmm cugraph custrings cudf"
export ALL_REPOS="$CODE_REPOS notebooks notebooks-extended"
export PYTHON_DIRS="rmm/python
                    cugraph/python
                    custrings/python
                    cudf/python/cudf
                    cudf/python/dask_cudf"

# Create .env file for the compose repo
source "$PWD/compose/scripts/create-compose-env.sh"
# Create the vscode 
source "$PWD/compose/scripts/create-vscode-workspace.sh"
# Ensure repos are cloned
source "$PWD/compose/scripts/clone-rapids-repositories.sh"
# Create symlinks to compile_commands.json for C++ intellisense
source "$PWD/compose/scripts/setup-c++-intellisense.sh"
# Create VSCode settings files for Python debugging and intellisense
source "$PWD/compose/scripts/setup-python-intellisense.sh"

echo "RAPIDS workspace init success!"
