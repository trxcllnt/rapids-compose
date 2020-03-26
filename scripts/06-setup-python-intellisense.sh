#!/usr/bin/env bash

set -Eeo pipefail

COMPOSE_HOME=$(dirname $(realpath "$0"))
COMPOSE_HOME=$(realpath "$COMPOSE_HOME/../")
RAPIDS_HOME=$(realpath "$COMPOSE_HOME/../")

cd "$RAPIDS_HOME"

PYTHON_DIRS="${PYTHON_DIRS:-rmm/python
                            cuml/python
                            cugraph/python
                            cudf/python/cudf
                            cudf/python/nvstrings
                            cudf/python/dask_cudf
                            cuspatial/python/cuspatial}"

cat << EOF > "$COMPOSE_HOME/etc/rapids/.vscode/python-settings.json"
{
    "python.analysis.memory.keepLibraryAst": true,
    "python.analysis.memory.keepLibraryLocalVariables": true,
    "python.autoComplete.extraPaths": [
        "$RAPIDS_HOME/rmm/python/rmm",
        "$RAPIDS_HOME/cudf/python/nvstrings",
        "$RAPIDS_HOME/cudf/python/cudf/cudf",
        "$RAPIDS_HOME/cudf/python/dask_cudf/dask_cudf",
        "$RAPIDS_HOME/cuml/python/cuml",
        "$RAPIDS_HOME/cugraph/python/cugraph",
        "$RAPIDS_HOME/cuspatial/python/cuspatial",
    ],
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
