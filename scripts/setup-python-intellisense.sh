#!/usr/bin/env bash

set -e
cd $(dirname "$(realpath "$0")")/../../

PYTHON_DIRS="${PYTHON_DIRS:-rmm/python
                            cugraph/python
                            custrings/python
                            cudf/python/cudf
                            cudf/python/dask_cudf}"

cat << EOF > "$PWD/compose/etc/rapids/.vscode/python-settings.json"
{
    "python.pythonPath": "$PWD/compose/etc/conda/envs/rapids/bin/python"
}
EOF

for PYDIR in $PYTHON_DIRS; do
    mkdir -p "$PWD/$PYDIR/.vscode"
    # Symlink the python-settings.json file from compose/etc/rapids/
    ln -f -s "$PWD/compose/etc/rapids/.vscode/python-settings.json" "$PWD/$PYDIR/.vscode/settings.json"
    cat << EOF > "$PWD/$PYDIR/.vscode/launch.json"
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
