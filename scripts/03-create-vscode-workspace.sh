#!/usr/bin/env bash

set -Eeo pipefail

cd $(dirname "$(realpath "$0")")/../../

create_vscode_workspace() {
    cat << EOF > "$PWD/rapids.code-workspace"
{
    "folders": [
        { "name": "compose", "path": "compose" },
        { "name": "rmm", "path": "rmm" },
        { "name": "cudf", "path": "cudf" },
        { "name": "cudf-cpp", "path": "cudf/cpp" },
        { "name": "cudf-java", "path": "cudf/java" },
        { "name": "cudf-python", "path": "cudf/python/cudf" },
        { "name": "dask-cudf-python", "path": "cudf/python/dask_cudf" },
        { "name": "cugraph", "path": "cugraph" },
        { "name": "cugraph-cpp", "path": "cugraph/cpp" },
        { "name": "cugraph-python", "path": "cugraph/python" },
        { "name": "nvstrings-python", "path": "cudf/python/nvstrings" },
        { "name": "notebooks", "path": "notebooks" },
        { "name": "notebooks-contrib", "path": "notebooks-contrib" },
    ],
    "settings": {

        "C_Cpp.formatting": "Disabled",
        "C_Cpp.autocomplete": "Disabled",
        "C_Cpp.errorSquiggles": "Disabled",
        "C_Cpp.intelliSenseEngine": "Disabled",
        "C_Cpp.configurationWarnings": "Disabled",
        "C_Cpp.autoAddFileAssociations": false,
        "C_Cpp.vcpkg.enabled": false,

        "clangd.syncFileEvents": true,
        "clangd.path": "/usr/bin/clangd",
        "clangd.semanticHighlighting": true,
        "clangd.trace": "$HOME/.vscode/clangd.log",
        "clangd.arguments": [
            "--log", "info",
            "--pch-storage=memory",
            "--compile-commands-dir=",
            "--background-index=false",
            "--fallback-style", "Chromium"
        ],
        "search.exclude": {
            "**/.ccache": true,
            "**/build/b-*": true,
            "**/build/debug": true,
            "**/build/release": true,
        },
        "files.associations": {
            "*.cu": "cuda",
            "*.cuh": "cuda",
            "**/libcudacxx/include/**/*": "cpp"
        },
        "files.watcherExclude": {
            "**/.git/objects/**": true,
            "**/.git/subtree-cache/**": true,
            "**/node_modules/**": true,

            "**/.ccache": true,
            "**/build/b-*": true,
            "**/build/debug": true,
            "**/build/release": true,
            "**/build/include": true,
            "**/etc/conda/**": true,
            "**/etc/.ccache/**": true,
            "**/cudf/**/*.so": true,
            "**/cudf/**/*.cpp": true,
            "**/cugraph/**/*.so": true,
            "**/cugraph/**/*.cpp": true,
            "**/build/lib.linux-x86_64*": true,
            "**/build/temp.linux-x86_64*": true,
            "**/build/bdist.linux-x86_64*": true,
        },
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

            "**/build/include": true,
            "**/cudf/**/*.so": true,
            "**/cudf/**/*.cpp": true,
            "**/cugraph/**/*.so": true,
            "**/cugraph/**/*.cpp": true,
            "**/build/lib.linux-x86_64*": true,
            "**/build/temp.linux-x86_64*": true,
            "**/build/bdist.linux-x86_64*": true,
        }
    }
}
EOF
}

if [ ! -f "$PWD/rapids.code-workspace" ]; then
    create_vscode_workspace
else
    while true; do
        read -p "Do you wish to overwrite your existing vscode rapids.code-workspace? (y/n) " yn </dev/tty
        case $yn in
            [Nn]* ) break;;
            [Yy]* ) create_vscode_workspace; break;;
            * ) echo "Please answer 'y' or 'n'";;
        esac
    done
fi
