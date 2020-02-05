#!/usr/bin/env bash

set -Eeo pipefail

COMPOSE_HOME=$(dirname $(realpath "$0"))
COMPOSE_HOME=$(realpath "$COMPOSE_HOME/../")
RAPIDS_HOME=$(realpath "$COMPOSE_HOME/../")

cd "$RAPIDS_HOME"

PYTHON_DIRS="${PYTHON_DIRS:-rmm/python
                            cugraph/python
                            cudf/python/cudf
                            cudf/python/nvstrings
                            cudf/python/dask_cudf}"

cat << EOF > "$COMPOSE_HOME/etc/rapids/.vscode/python-settings.json"
{
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
