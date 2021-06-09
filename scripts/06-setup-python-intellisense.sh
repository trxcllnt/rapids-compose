#!/usr/bin/env bash

set -Eeo pipefail

COMPOSE_HOME=$(dirname $(realpath "$0"))
COMPOSE_HOME=$(realpath "$COMPOSE_HOME/../")
RAPIDS_HOME=$(realpath "$COMPOSE_HOME/../")

cd "$RAPIDS_HOME"

PYTHON_DIRS="${PYTHON_DIRS:-rmm/python
                            raft/python \
                            cuml/python
                            cugraph/python
                            cudf/python/cudf
                            cudf/python/dask_cudf
                            cuspatial/python/cuspatial}"

cat << EOF > "$COMPOSE_HOME/etc/rapids/.vscode/python-settings.json"
{
    "python.analysis.memory.keepLibraryAst": true,
    "python.analysis.memory.keepLibraryLocalVariables": true,
    "python.autoComplete.extraPaths": [
        "$RAPIDS_HOME/rmm/python",
        "$RAPIDS_HOME/raft/python",
        "$RAPIDS_HOME/cudf/python/cudf",
        "$RAPIDS_HOME/cudf/python/dask_cudf",
        "$RAPIDS_HOME/cuml/python",
        "$RAPIDS_HOME/cugraph/python",
        "$RAPIDS_HOME/cuspatial/python/cuspatial",
    ],
    "python.languageServer": "Pylance",
    "python.condaPath": "$COMPOSE_HOME/etc/conda/bin/conda",
    "python.pythonPath": "$COMPOSE_HOME/etc/conda/envs/rapids/bin/python"
}
EOF

for PYDIR in $PYTHON_DIRS; do
    mkdir -p "$RAPIDS_HOME/$PYDIR/.vscode"
    # Symlink the python-settings.json file from compose/etc/rapids/
    ln -f -s "$COMPOSE_HOME/etc/rapids/.vscode/python-settings.json" "$RAPIDS_HOME/$PYDIR/.vscode/settings.json"
    cat << EOF > "$RAPIDS_HOME/$PYDIR/.vscode/launch.json"
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "$PYDIR",
            "type": "python",
            "request": "attach",
            "port": 5678,
            "host": "localhost",
            "pathMappings": [{
                "localRoot": "\${workspaceFolder}",
                "remoteRoot": "\${workspaceFolder}"
            }]
        }
    ]
}
EOF
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
            "ms-python.python" \
            "guyskk.language-cython";
    fi
done
