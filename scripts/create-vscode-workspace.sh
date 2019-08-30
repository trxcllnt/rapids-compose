#!/usr/bin/env bash

set -e

create_vscode_workspace() {
    cat << EOF > "$PWD/rapids.code-workspace"
{
    "folders": [
        { "name": "compose", "path": "compose" },
        { "name": "rmm", "path": "rmm" },
        { "name": "cudf-cpp", "path": "cudf/cpp" },
        { "name": "cudf-java", "path": "cudf/java" },
        { "name": "cudf-python", "path": "cudf/python/cudf" },
        { "name": "dask-cudf-python", "path": "cudf/python/dask_cudf" },
        { "name": "cugraph-cpp", "path": "cugraph/cpp" },
        { "name": "cugraph-python", "path": "cugraph/python" },
        { "name": "custrings-cpp", "path": "custrings/cpp" },
        { "name": "custrings-python", "path": "custrings/python" },
        { "name": "notebooks", "path": "notebooks" },
        { "name": "notebooks-extended", "path": "notebooks-extended" },
    ],
    "settings": {
        "search.exclude": {
            "$PWD/compose/etc/conda": true,
            "$PWD/rmm/build/include": true,
            "$PWD/cudf/cpp/build/include": true,
            "$PWD/cugraph/cpp/build/include": true,
            "$PWD/custrings/cpp/build/include": true,
        },
        "files.associations": { "*.cu": "cpp", "*.cuh": "cpp", },
        "files.exclude": {

            "**/.git": true,
            "**/.svn": true,
            "**/.hg": true,
            "**/CVS": true,
            "**/.DS_Store": true,
            "**/*.egg": true,
            "**/*.egg-info": true,
            "**/__pycache__": true,
            "**/.pytest_cache": true,

            "$PWD/rmm/build/include": true,
            "$PWD/rmm/python/build/lib.linux-x86_64*": true,
            "$PWD/rmm/python/build/temp.linux-x86_64*": true,
            "$PWD/rmm/python/build/bdist.linux-x86_64*": true,

            "$PWD/cudf/cpp/build/include": true,
            "$PWD/cudf/python/cudf/_lib/**/*.so": true,
            "$PWD/cudf/python/cudf/_lib/**/*.cpp": true,
            "$PWD/cudf/python/cudf/build/lib.linux-x86_64*": true,
            "$PWD/cudf/python/cudf/build/temp.linux-x86_64*": true,
            "$PWD/cudf/python/cudf/build/bdist.linux-x86_64*": true,
            "$PWD/cudf/python/dask_cudf/build/lib.linux-x86_64*": true,
            "$PWD/cudf/python/dask_cudf/build/temp.linux-x86_64*": true,
            "$PWD/cudf/python/dask_cudf/build/bdist.linux-x86_64*": true,

            "$PWD/cugraph/cpp/build/include": true,
            "$PWD/cugraph/python/**/*.so": true,
            "$PWD/cugraph/python/**/*.cpp": true,
            "$PWD/cugraph/python/build/lib.linux-x86_64*": true,
            "$PWD/cugraph/python/build/temp.linux-x86_64*": true,
            "$PWD/cugraph/python/build/bdist.linux-x86_64*": true,

            "$PWD/custrings/cpp/build/include": true,
            "$PWD/custrings/python/build/lib.linux-x86_64*": true,
            "$PWD/custrings/python/build/temp.linux-x86_64*": true,
            "$PWD/custrings/python/build/bdist.linux-x86_64*": true,
        }
    }
}
EOF
}

if [ ! -f "$PWD/rapids.code-workspace" ]; then
    create_vscode_workspace
else
    while true; do
        read -p "Do you wish to overwrite the existing vscode rapids.code-workspace? (y/n) " yn </dev/tty
        case $yn in
            [Nn]* ) break;;
            [Yy]* ) create_vscode_workspace; break;;
            * ) echo "Please answer 'y' or 'n'";;
        esac
    done
fi
