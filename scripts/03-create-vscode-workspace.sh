#!/usr/bin/env bash

set -Eeo pipefail

cd $(dirname "$(realpath "$0")")/../../

rapids_vscode_workspace() {
    echo "\
{
    \"folders\": [
        {
            \"name\": \"compose\",
            \"path\": \"compose\"
        },
        {
            \"name\": \"rmm\",
            \"path\": \"rmm\"
        },
        {
            \"name\": \"cudf\",
            \"path\": \"cudf\"
        },
        {
            \"name\": \"cudf-cpp\",
            \"path\": \"cudf/cpp\"
        },
        {
            \"name\": \"cudf-java\",
            \"path\": \"cudf/java\"
        },
        {
            \"name\": \"cudf-python\",
            \"path\": \"cudf/python/cudf\"
        },
        {
            \"name\": \"dask-cudf-python\",
            \"path\": \"cudf/python/dask_cudf\"
        },
        {
            \"name\": \"cugraph\",
            \"path\": \"cugraph\"
        },
        {
            \"name\": \"cugraph-cpp\",
            \"path\": \"cugraph/cpp\"
        },
        {
            \"name\": \"cugraph-python\",
            \"path\": \"cugraph/python\"
        },
        {
            \"name\": \"cuML\",
            \"path\": \"cuml\"
        },
        {
            \"name\": \"cuML-cpp\",
            \"path\": \"cuml/cpp\"
        },
        {
            \"name\": \"cuML-python\",
            \"path\": \"cuml/python\"
        },
        {
            \"name\": \"nvstrings-python\",
            \"path\": \"cudf/python/nvstrings\"
        },
        {
            \"name\": \"notebooks\",
            \"path\": \"notebooks\"
        },
        {
            \"name\": \"notebooks-contrib\",
            \"path\": \"notebooks-contrib\"
        }
    ],
    \"settings\": {

        \"C_Cpp.formatting\": \"Disabled\",
        \"C_Cpp.autocomplete\": \"Disabled\",
        \"C_Cpp.errorSquiggles\": \"Disabled\",
        \"C_Cpp.intelliSenseEngine\": \"Disabled\",
        \"C_Cpp.configurationWarnings\": \"Disabled\",
        \"C_Cpp.autoAddFileAssociations\": false,
        \"C_Cpp.vcpkg.enabled\": false,

        \"clangd.syncFileEvents\": true,
        \"clangd.path\": \"/usr/bin/clangd\",
        \"clangd.semanticHighlighting\": true,
        \"clangd.trace\": \"$HOME/.vscode/clangd.log\",
        \"clangd.arguments\": [
            \"-j=4\",
            \"--log=info\",
            \"--pch-storage=disk\",
            \"--fallback-style=Chromium\",
            \"--compile-commands-dir=\",
            \"--background-index=true\",
            \"--all-scopes-completion\",
            \"--header-insertion=never\",
            \"--suggest-missing-includes\",
            \"--completion-style=detailed\",
            \"--header-insertion-decorators\",
        ],
        \"search.exclude\": {
            \"**/.ccache\": true,
            \"**/build/b-*\": true,
            \"**/build/debug\": true,
            \"**/build/release\": true,
        },
        \"files.associations\": {
            \"*.cu\": \"cuda\",
            \"*.cuh\": \"cuda\",
            \"**/libcudacxx/include/**/*\": \"cpp\"
        },
        \"files.watcherExclude\": {
            \"**/.git/objects/**\": true,
            \"**/.git/subtree-cache/**\": true,
            \"**/node_modules/**\": true,
            \"**/.ccache\": true,
            \"**/build/b-*\": true,
            \"**/build/debug\": true,
            \"**/build/release\": true,
            \"**/build/include\": true,
            \"**/etc/conda/**\": true,
            \"**/etc/.ccache/**\": true,
            \"**/cudf/**/*.so\": true,
            \"**/cudf/**/*.cpp\": true,
            \"**/cuml/**/*.so\": true,
            \"**/cuml/**/*.cpp\": true,
            \"**/cugraph/**/*.so\": true,
            \"**/cugraph/**/*.cpp\": true,
            \"**/build/lib.linux-x86_64*\": true,
            \"**/build/temp.linux-x86_64*\": true,
            \"**/build/bdist.linux-x86_64*\": true,
        },
        \"files.exclude\": {
            \"**/.git\": true,
            \"**/.svn\": true,
            \"**/.hg\": true,
            \"**/CVS\": true,
            \"**/.DS_Store\": true,
            \"**/*.egg\": true,
            \"**/*.egg-info\": true,
            \"**/__pycache__\": true,
            \"**/.pytest_cache\": true,
            \"**/build/include\": true,
            \"**/cudf/**/*.so\": true,
            \"**/cudf/**/*.cpp\": true,
            \"**/cuml/**/*.so\": true,
            \"**/cuml/**/*.cpp\": true,
            \"**/cugraph/**/*.so\": true,
            \"**/cugraph/**/*.cpp\": true,
            \"**/build/lib.linux-x86_64*\": true,
            \"**/build/temp.linux-x86_64*\": true,
            \"**/build/bdist.linux-x86_64*\": true,
        }
    }
}
"
}

# cat << EOF > "$PWD/rapids.code-workspace"

if [ ! -f "$PWD/rapids.code-workspace" ]; then
    rapids_vscode_workspace > "$PWD/rapids.code-workspace"
fi

CHANGED="$(diff -qwB "$PWD/rapids.code-workspace" <(rapids_vscode_workspace) || true)"

if [ -n "${CHANGED// }" ]; then
    echo "Difference between current rapids.code-workspace and proposed rapids.code-workspace:";
    diff -wBy --suppress-common-lines "$PWD/rapids.code-workspace" <(rapids_vscode_workspace) || true;
    while true; do
        read -p "Do you wish to overwrite your current rapids.code-workspace file? (y/n) " yn </dev/tty
        case $yn in
            [Nn]* ) break;;
            [Yy]* ) rapids_vscode_workspace > "$PWD/rapids.code-workspace"; break;;
            * ) echo "Please answer 'y' or 'n'";;
        esac
    done
fi
