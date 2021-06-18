#!/usr/bin/env bash

set -Eeo pipefail

COMPOSE_HOME=$(dirname $(realpath "$0"))
COMPOSE_HOME=$(realpath "$COMPOSE_HOME/../")
RAPIDS_HOME=$(realpath "$COMPOSE_HOME/../")

cd "$RAPIDS_HOME"

rapids_vscode_workspace() {
cat << EOF
{
    "folders": [
        {
            "name": "compose",
            "path": "compose"
        },
        {
            "name": "rmm-cpp",
            "path": "rmm"
        },
        {
            "name": "rmm-python",
            "path": "rmm/python"
        },
        {
            "name": "cudf",
            "path": "cudf"
        },
        {
            "name": "cudf-cpp",
            "path": "cudf/cpp"
        },
        {
            "name": "cudf-java",
            "path": "cudf/java"
        },
        {
            "name": "cudf-python",
            "path": "cudf/python/cudf"
        },
        {
            "name": "dask-cudf-python",
            "path": "cudf/python/dask_cudf"
        },
        {
            "name": "cugraph",
            "path": "cugraph"
        },
        {
            "name": "cugraph-cpp",
            "path": "cugraph/cpp"
        },
        {
            "name": "cugraph-python",
            "path": "cugraph/python"
        },
        {
            "name": "cuML",
            "path": "cuml"
        },
        {
            "name": "cuML-cpp",
            "path": "cuml/cpp"
        },
        {
            "name": "cuML-python",
            "path": "cuml/python"
        },
        {
            "name": "raft",
            "path": "raft"
        },
        {
            "name": "raft-cpp",
            "path": "raft/cpp"
        },
        {
            "name": "raft-python",
            "path": "raft/python"
        },
        {
            "name": "cuspatial",
            "path": "cuspatial"
        },
        {
            "name": "cuspatial-cpp",
            "path": "cuspatial/cpp"
        },
        {
            "name": "cuspatial-python",
            "path": "cuspatial/python/cuspatial"
        },
        {
            "name": "notebooks-contrib",
            "path": "notebooks-contrib"
        }
    ],
    "extensions": {
        "recommendations": [
            "twxs.cmake",
            "ms-python.python",
            "ms-python.vscode-pylance",
            "ms-vscode.cpptools",
            "xaver.clang-format",
            "cschlosser.doxdocgen",
            "guyskk.language-cython",
            "kriegalex.vscode-cudacpp",
            "augustocdias.tasks-shell-input",
            "dotiful.dotfiles-syntax-highlighting",
            "llvm-vs-code-extensions.vscode-clangd",
        ]
    },
    "settings": {

        "git.ignoreLimitWarning": true,

        // Fixes to make the "<ctrl>+<shift>+<B>" tasks list launch instantly
        "task.autoDetect": "off",
        "typescript.tsc.autoDetect": "off",

        // "C_Cpp.loggingLevel": "Debug",
        // "C_Cpp.default.intelliSenseMode": "linux-gcc-x64",
        // "C_Cpp.formatting": "Disabled",
        // "C_Cpp.autocomplete": "Default",
        // "C_Cpp.errorSquiggles": "EnabledIfIncludesResolve",
        // "C_Cpp.intelliSenseEngine": "Default",
        // "C_Cpp.intelliSenseEngineFallback": "Disabled",
        // "C_Cpp.configurationWarnings": "Enabled",
        // "C_Cpp.enhancedColorization": "Enabled",
        // "C_Cpp.intelliSenseCachePath": "$COMPOSE_HOME/etc/rapids/.vscode/vscode-cpptools",
        // "C_Cpp.autoAddFileAssociations": false,
        // "C_Cpp.vcpkg.enabled": false,

        "C_Cpp.formatting": "Disabled",
        "C_Cpp.autocomplete": "Disabled",
        "C_Cpp.errorSquiggles": "Disabled",
        "C_Cpp.intelliSenseEngine": "Disabled",
        "C_Cpp.configurationWarnings": "Disabled",
        "C_Cpp.autoAddFileAssociations": false,
        "C_Cpp.vcpkg.enabled": false,

        // doxdocgen doxygen style
        "doxdocgen.generic.returnTemplate": "@return ",

        // Configure the xaver.clang-format plugin to use the conda-installed clang-format
        "clang-format.fallbackStyle": "Google",
        "clang-format.executable": "$COMPOSE_HOME/etc/conda/envs/rapids/bin/clang-format",
        "[c]": { "editor.defaultFormatter": "xaver.clang-format" },
        "[cpp]": { "editor.defaultFormatter": "xaver.clang-format" },
        "[cuda]": { "editor.defaultFormatter": "xaver.clang-format" },
        "[cuda-cpp]": { "editor.defaultFormatter": "xaver.clang-format" },

        "python.languageServer": "Pylance",
        "python.condaPath": "$COMPOSE_HOME/etc/conda/bin/conda",
        // Set this so vscode-python doesn't fight itself over which python binary to use :facepalm:
        "python.pythonPath": "$COMPOSE_HOME/etc/conda/envs/rapids/bin/python",

        "clangd.path": "/usr/bin/clangd",
        "clangd.semanticHighlighting": true,
        "clangd.trace": "$HOME/.vscode/clangd.log",
        "clangd.arguments": [
            "-j=4",
            "--log=info",
            "--pch-storage=disk",
            "--completion-parse=auto",
            "--fallback-style=Google",
            "--compile-commands-dir=",
            "--background-index=true",
            "--all-scopes-completion",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--header-insertion-decorators"
        ],
        "search.exclude": {
            "**/.clangd": true,
            "**/.clangd/**": true,
            "**/etc/llvm": true,
            "**/etc/llvm/**": true,
            "**/etc/conda": true,
            "**/etc/conda/**": true,
            "**/etc/.ccache": true,
            "**/etc/.ccache/**": true,
            "**/build/cuda-*": true,
            "**/build/debug": true,
            "**/build/release": true,
            "**/build/relwithdebinfo": true
        },
        "files.insertFinalNewline": true,
        "files.trimFinalNewlines": true,
        "files.associations": {
            "*.cu": "cuda",
            "*.cuh": "cuda",
            // "*.cu": "cuda-cpp",
            // "*.cuh": "cuda-cpp",
            "**/libcudacxx/include/**/*": "cpp"
        },
        "files.watcherExclude": {
            "**/.git/objects/**": true,
            "**/.git/subtree-cache/**": true,
            "**/node_modules/**": true,
            "**/.clangd": true,
            "**/.clangd/**": true,
            "**/etc/llvm": true,
            "**/etc/conda": true,
            "**/etc/.ccache": true,
            "**/build/lib": true,
            "**/build/cuda-*": true,
            "**/build/debug": true,
            "**/build/release": true,
            "**/build/relwithdebinfo": true,
            "**/build/include": true,
            "**/etc/llvm/**": true,
            "**/etc/conda/**": true,
            "**/etc/.ccache/**": true,
            "**/rmm/**/*.so": true,
            "**/rmm/**/*.cpp": true,
            "**/cudf/**/*.so": true,
            "**/cudf/**/*.cpp": true,
            "**/cuml/**/*.so": true,
            "**/cuml/**/*.cpp": true,
            "**/cugraph/**/*.so": true,
            "**/cugraph/**/*.cpp": true,
            "**/cuspatial/**/*.so": true,
            "**/cuspatial/**/*.cpp": true,
            "**/build/lib.linux-x86_64*": true,
            "**/build/temp.linux-x86_64*": true,
            "**/build/bdist.linux-x86_64*": true
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
            "**/.clangd": true,
            "**/.clangd/**": true,
            "**/build/lib": true,
            "**/build/include": true,
            "**/rmm/**/*.so": true,
            "**/rmm/**/*.cpp": true,
            "**/cudf/**/*.so": true,
            "**/cudf/**/*.cpp": true,
            "**/cuml/**/*.so": true,
            "**/cuml/**/*.cpp": true,
            "**/cugraph/**/*.so": true,
            "**/cugraph/**/*.cpp": true,
            "**/cuspatial/**/*.so": true,
            "**/cuspatial/**/*.cpp": true,
            "**/build/lib.linux-x86_64*": true,
            "**/build/temp.linux-x86_64*": true,
            "**/build/bdist.linux-x86_64*": true
        },
        "terminal.integrated.automationShell.linux": "/bin/bash",
        "terminal.integrated.shell.linux": "/bin/bash",
        "terminal.integrated.enableFileLinks": true,
        "terminal.integrated.shellArgs.linux": ["-c", "rapids_container=\$(docker ps | grep rapidsai/\$(whoami)/rapids | cut -d\" \" -f1 || echo \"\"); if [ \"\$rapids_container\" == \"\" ]; then exec \$SHELL; else exec docker exec -u \${UID}:\${GID} -it -w \"\$PWD\" \"\$rapids_container\" bash -li; fi"],
    },
    "tasks": {
        "version": "2.0.0",
        "tasks": [
            {
                "label": "Configure and Build all RAPIDS projects",
                "type": "shell",
                "command": "docker exec -u \${UID}:\${GID} -it \${input:rapids_container} bash -lic \"build-rapids\"",
                "group": "build",
                "problemMatcher": []
            },
            {
                "label": "Configure and Build rmm C++",
                "type": "shell",
                "command": "docker exec -u \${UID}:\${GID} -it \${input:rapids_container} bash -lic \"build-rmm-cpp\"",
                "group": "build",
                "problemMatcher": [
                    { "owner": "cuda", "fileLocation": ["relative", "\${input:rmm_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 3, "message": 4, "regexp": "^(.*)\\\((\\\d+)\\\):\\\s+(error|warning|note|info):\\\s+(.*)\$"} },
                    { "owner": "cpp", "fileLocation": ["relative", "\${input:rmm_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 4, "message": 5, "regexp": "^(.*):(\\\d+):(\\\d+):\\\s+(error|warning|note|info):\\\s+(.*)\$"} }
                ]
            },
            {
                "label": "Configure and Build cuDF C++",
                "type": "shell",
                "command": "docker exec -u \${UID}:\${GID} -it \${input:rapids_container} bash -lic \"build-cudf-cpp\"",
                "group": "build",
                "problemMatcher": [
                    { "owner": "cuda", "fileLocation": ["relative", "\${input:cudf_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 3, "message": 4, "regexp": "^(.*)\\\((\\\d+)\\\):\\\s+(error|warning|note|info):\\\s+(.*)\$"} },
                    { "owner": "cpp", "fileLocation": ["relative", "\${input:cudf_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 4, "message": 5, "regexp": "^(.*):(\\\d+):(\\\d+):\\\s+(error|warning|note|info):\\\s+(.*)\$"} }
                ]
            },
            {
                "label": "Configure and Build cuML C++",
                "type": "shell",
                "command": "docker exec -u \${UID}:\${GID} -it \${input:rapids_container} bash -lic \"build-cuml-cpp\"",
                "group": "build",
                "problemMatcher": [
                    { "owner": "cuda", "fileLocation": ["relative", "\${input:cuml_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 3, "message": 4, "regexp": "^(.*)\\\((\\\d+)\\\):\\\s+(error|warning|note|info):\\\s+(.*)\$"} },
                    { "owner": "cpp", "fileLocation": ["relative", "\${input:cuml_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 4, "message": 5, "regexp": "^(.*):(\\\d+):(\\\d+):\\\s+(error|warning|note|info):\\\s+(.*)\$"} }
                ]
            },
            {
                "label": "Configure and Build cuGraph C++",
                "type": "shell",
                "command": "docker exec -u \${UID}:\${GID} -it \${input:rapids_container} bash -lic \"build-cugraph-cpp\"",
                "group": "build",
                "problemMatcher": [
                    { "owner": "cuda", "fileLocation": ["relative", "\${input:cugraph_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 3, "message": 4, "regexp": "^(.*)\\\((\\\d+)\\\):\\\s+(error|warning|note|info):\\\s+(.*)\$"} },
                    { "owner": "cpp", "fileLocation": ["relative", "\${input:cugraph_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 4, "message": 5, "regexp": "^(.*):(\\\d+):(\\\d+):\\\s+(error|warning|note|info):\\\s+(.*)\$"} }
                ]
            },
            {
                "label": "Configure and Build cuSpatial C++",
                "type": "shell",
                "command": "docker exec -u \${UID}:\${GID} -it \${input:rapids_container} bash -lic \"build-cuspatial-cpp\"",
                "group": "build",
                "problemMatcher": [
                    { "owner": "cuda", "fileLocation": ["relative", "\${input:cuspatial_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 3, "message": 4, "regexp": "^(.*)\\\((\\\d+)\\\):\\\s+(error|warning|note|info):\\\s+(.*)\$"} },
                    { "owner": "cpp", "fileLocation": ["relative", "\${input:cuspatial_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 4, "message": 5, "regexp": "^(.*):(\\\d+):(\\\d+):\\\s+(error|warning|note|info):\\\s+(.*)\$"} }
                ]
            },
            {
                "label": "Recompile rmm C++ (fast)",
                "type": "shell",
                "command": "docker exec -u \${UID}:\${GID} -it \${input:rapids_container} bash -lic \"update-environment-variables && ninja -C \\\\\$RMM_ROOT\"",
                "group": "build",
                "options": { "cwd": "\${input:rmm_cpp_build_path}" },
                "problemMatcher": [
                    { "owner": "cuda", "fileLocation": ["relative", "\${input:rmm_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 3, "message": 4, "regexp": "^(.*)\\\((\\\d+)\\\):\\\s+(error|warning|note|info):\\\s+(.*)\$"} },
                    { "owner": "cpp", "fileLocation": ["relative", "\${input:rmm_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 4, "message": 5, "regexp": "^(.*):(\\\d+):(\\\d+):\\\s+(error|warning|note|info):\\\s+(.*)\$"} }
                ]
            },
            {
                "label": "Recompile cuDF C++ (fast)",
                "type": "shell",
                "command": "docker exec -u \${UID}:\${GID} -it \${input:rapids_container} bash -lic \"update-environment-variables && ninja -C \\\\\$CUDF_ROOT\"",
                "group": "build",
                "options": { "cwd": "\${input:cudf_cpp_build_path}" },
                "problemMatcher": [
                    { "owner": "cuda", "fileLocation": ["relative", "\${input:cudf_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 3, "message": 4, "regexp": "^(.*)\\\((\\\d+)\\\):\\\s+(error|warning|note|info):\\\s+(.*)\$"} },
                    { "owner": "cpp", "fileLocation": ["relative", "\${input:cudf_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 4, "message": 5, "regexp": "^(.*):(\\\d+):(\\\d+):\\\s+(error|warning|note|info):\\\s+(.*)\$"} }
                ]
            },
            {
                "label": "Recompile cuML C++ (fast)",
                "type": "shell",
                "command": "docker exec -u \${UID}:\${GID} -it \${input:rapids_container} bash -lic \"update-environment-variables && ninja -C \\\\\$CUML_ROOT\"",
                "group": "build",
                "options": { "cwd": "\${input:cuml_cpp_build_path}" },
                "problemMatcher": [
                    { "owner": "cuda", "fileLocation": ["relative", "\${input:cuml_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 3, "message": 4, "regexp": "^(.*)\\\((\\\d+)\\\):\\\s+(error|warning|note|info):\\\s+(.*)\$"} },
                    { "owner": "cpp", "fileLocation": ["relative", "\${input:cuml_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 4, "message": 5, "regexp": "^(.*):(\\\d+):(\\\d+):\\\s+(error|warning|note|info):\\\s+(.*)\$"} }
                ]
            },
            {
                "label": "Recompile cuGraph C++ (fast)",
                "type": "shell",
                "command": "docker exec -u \${UID}:\${GID} -it \${input:rapids_container} bash -lic \"update-environment-variables && ninja -C \\\\\$CUGRAPH_ROOT\"",
                "group": "build",
                "options": { "cwd": "\${input:cugraph_cpp_build_path}" },
                "problemMatcher": [
                    { "owner": "cuda", "fileLocation": ["relative", "\${input:cugraph_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 3, "message": 4, "regexp": "^(.*)\\\((\\\d+)\\\):\\\s+(error|warning|note|info):\\\s+(.*)\$"} },
                    { "owner": "cpp", "fileLocation": ["relative", "\${input:cugraph_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 4, "message": 5, "regexp": "^(.*):(\\\d+):(\\\d+):\\\s+(error|warning|note|info):\\\s+(.*)\$"} }
                ]
            },
            {
                "label": "Recompile cuSpatial C++ (fast)",
                "type": "shell",
                "command": "docker exec -u \${UID}:\${GID} -it \${input:rapids_container} bash -lic \"update-environment-variables && ninja -C \\\\\$CUSPATIAL_ROOT\"",
                "group": "build",
                "options": { "cwd": "\${input:cuspatial_cpp_build_path}" },
                "problemMatcher": [
                    { "owner": "cuda", "fileLocation": ["relative", "\${input:cuspatial_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 3, "message": 4, "regexp": "^(.*)\\\((\\\d+)\\\):\\\s+(error|warning|note|info):\\\s+(.*)\$"} },
                    { "owner": "cpp", "fileLocation": ["relative", "\${input:cuspatial_cpp_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 4, "message": 5, "regexp": "^(.*):(\\\d+):(\\\d+):\\\s+(error|warning|note|info):\\\s+(.*)\$"} }
                ]
            },
            {
                "label": "Recompile rmm Cython/Python (fast)",
                "type": "shell",
                "command": "docker exec -u \${UID}:\${GID} -it \${input:rapids_container} bash -lic \"build-rmm-python\"",
                "group": "build",
                "options": { "cwd": "\${input:rmm_python_build_path}" },
                "problemMatcher": [
                    { "owner": "cuda", "fileLocation": ["relative", "\${input:rmm_python_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 3, "message": 4, "regexp": "^(.*)\\\((\\\d+)\\\):\\\s+(error|warning|note|info):\\\s+(.*)\$"} },
                    { "owner": "cpp", "fileLocation": ["relative", "\${input:rmm_python_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 4, "message": 5, "regexp": "^(.*):(\\\d+):(\\\d+):\\\s+(error|warning|note|info):\\\s+(.*)\$"} }
                ]
            },
            {
                "label": "Recompile cuDF Cython/Python (fast)",
                "type": "shell",
                "command": "docker exec -u \${UID}:\${GID} -it \${input:rapids_container} bash -lic \"build-cudf-python\"",
                "group": "build",
                "options": { "cwd": "\${input:cudf_python_build_path}" },
                "problemMatcher": [
                    { "owner": "cuda", "fileLocation": ["relative", "\${input:cudf_python_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 3, "message": 4, "regexp": "^(.*)\\\((\\\d+)\\\):\\\s+(error|warning|note|info):\\\s+(.*)\$"} },
                    { "owner": "cpp", "fileLocation": ["relative", "\${input:cudf_python_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 4, "message": 5, "regexp": "^(.*):(\\\d+):(\\\d+):\\\s+(error|warning|note|info):\\\s+(.*)\$"} }
                ]
            },
            {
                "label": "Recompile cuML Cython/Python (fast)",
                "type": "shell",
                "command": "docker exec -u \${UID}:\${GID} -it \${input:rapids_container} bash -lic \"build-cuml-python\"",
                "group": "build",
                "options": { "cwd": "\${input:cuml_python_build_path}" },
                "problemMatcher": [
                    { "owner": "cuda", "fileLocation": ["relative", "\${input:cuml_python_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 3, "message": 4, "regexp": "^(.*)\\\((\\\d+)\\\):\\\s+(error|warning|note|info):\\\s+(.*)\$"} },
                    { "owner": "cpp", "fileLocation": ["relative", "\${input:cuml_python_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 4, "message": 5, "regexp": "^(.*):(\\\d+):(\\\d+):\\\s+(error|warning|note|info):\\\s+(.*)\$"} }
                ]
            },
            {
                "label": "Recompile cuGraph Cython/Python (fast)",
                "type": "shell",
                "command": "docker exec -u \${UID}:\${GID} -it \${input:rapids_container} bash -lic \"build-cugraph-python\"",
                "group": "build",
                "options": { "cwd": "\${input:cugraph_python_build_path}" },
                "problemMatcher": [
                    { "owner": "cuda", "fileLocation": ["relative", "\${input:cugraph_python_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 3, "message": 4, "regexp": "^(.*)\\\((\\\d+)\\\):\\\s+(error|warning|note|info):\\\s+(.*)\$"} },
                    { "owner": "cpp", "fileLocation": ["relative", "\${input:cugraph_python_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 4, "message": 5, "regexp": "^(.*):(\\\d+):(\\\d+):\\\s+(error|warning|note|info):\\\s+(.*)\$"} }
                ]
            },
            {
                "label": "Recompile cuSpatial Cython/Python (fast)",
                "type": "shell",
                "command": "docker exec -u \${UID}:\${GID} -it \${input:rapids_container} bash -lic \"build-cuspatial-python\"",
                "group": "build",
                "options": { "cwd": "\${input:cuspatial_python_build_path}" },
                "problemMatcher": [
                    { "owner": "cuda", "fileLocation": ["relative", "\${input:cuspatial_python_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 3, "message": 4, "regexp": "^(.*)\\\((\\\d+)\\\):\\\s+(error|warning|note|info):\\\s+(.*)\$"} },
                    { "owner": "cpp", "fileLocation": ["relative", "\${input:cuspatial_python_build_path}"], "pattern": {"file": 1, "line": 2, "severity": 4, "message": 5, "regexp": "^(.*):(\\\d+):(\\\d+):\\\s+(error|warning|note|info):\\\s+(.*)\$"} }
                ]
            }
        ],
        "inputs": [
            {
                "type": "command",
                "id": "rmm_cpp_build_path",
                "command": "shellCommand.execute",
                "args": {
                    "useFirstResult": true,
                    "command": "docker exec \$(docker ps | grep rapidsai/\$(whoami)/rapids | cut -d\" \" -f1) bash -lic \"echo \\\\\$(realpath -m \\\\\$RMM_ROOT)\""
                }
            },
            {
                "type": "command",
                "id": "cudf_cpp_build_path",
                "command": "shellCommand.execute",
                "args": {
                    "useFirstResult": true,
                    "command": "docker exec \$(docker ps | grep rapidsai/\$(whoami)/rapids | cut -d\" \" -f1) bash -lic \"echo \\\\\$(realpath -m \\\\\$CUDF_ROOT)\""
                }
            },
            {
                "type": "command",
                "id": "cuml_cpp_build_path",
                "command": "shellCommand.execute",
                "args": {
                    "useFirstResult": true,
                    "command": "docker exec \$(docker ps | grep rapidsai/\$(whoami)/rapids | cut -d\" \" -f1) bash -lic \"echo \\\\\$(realpath -m \\\\\$CUML_ROOT)\""
                }
            },
            {
                "type": "command",
                "id": "cugraph_cpp_build_path",
                "command": "shellCommand.execute",
                "args": {
                    "useFirstResult": true,
                    "command": "docker exec \$(docker ps | grep rapidsai/\$(whoami)/rapids | cut -d\" \" -f1) bash -lic \"echo \\\\\$(realpath -m \\\\\$CUGRAPH_ROOT)\""
                }
            },
            {
                "type": "command",
                "id": "cuspatial_cpp_build_path",
                "command": "shellCommand.execute",
                "args": {
                    "useFirstResult": true,
                    "command": "docker exec \$(docker ps | grep rapidsai/\$(whoami)/rapids | cut -d\" \" -f1) bash -lic \"echo \\\\\$(realpath -m \\\\\$CUSPATIAL_ROOT)\""
                }
            },
            {
                "type": "command",
                "id": "rmm_python_build_path",
                "command": "shellCommand.execute",
                "args": {
                    "useFirstResult": true,
                    "command": "docker exec \$(docker ps | grep rapidsai/\$(whoami)/rapids | cut -d\" \" -f1) bash -lic \"echo \\\\\$(realpath -m \\\\\$RMM_HOME)/python\""
                }
            },
            {
                "type": "command",
                "id": "cudf_python_build_path",
                "command": "shellCommand.execute",
                "args": {
                    "useFirstResult": true,
                    "command": "docker exec \$(docker ps | grep rapidsai/\$(whoami)/rapids | cut -d\" \" -f1) bash -lic \"echo \\\\\$(realpath -m \\\\\$CUDF_HOME)/python\""
                }
            },
            {
                "type": "command",
                "id": "cuml_python_build_path",
                "command": "shellCommand.execute",
                "args": {
                    "useFirstResult": true,
                    "command": "docker exec \$(docker ps | grep rapidsai/\$(whoami)/rapids | cut -d\" \" -f1) bash -lic \"echo \\\\\$(realpath -m \\\\\$CUML_HOME)/python\""
                }
            },
            {
                "type": "command",
                "id": "cugraph_python_build_path",
                "command": "shellCommand.execute",
                "args": {
                    "useFirstResult": true,
                    "command": "docker exec \$(docker ps | grep rapidsai/\$(whoami)/rapids | cut -d\" \" -f1) bash -lic \"echo \\\\\$(realpath -m \\\\\$CUGRAPH_HOME)/python\""
                }
            },
            {
                "type": "command",
                "id": "cuspatial_python_build_path",
                "command": "shellCommand.execute",
                "args": {
                    "useFirstResult": true,
                    "command": "docker exec \$(docker ps | grep rapidsai/\$(whoami)/rapids | cut -d\" \" -f1) bash -lic \"echo \\\\\$(realpath -m \\\\\$CUSPATIAL_HOME)/python\""
                }
            },
            {
                "type": "command",
                "id": "rapids_container",
                "command": "shellCommand.execute",
                "args": {
                    "useFirstResult": true,
                    "command": "docker ps | grep rapidsai/\$(whoami)/rapids | cut -d\" \" -f1"
                }
            }
        ]
    }
}
EOF
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
