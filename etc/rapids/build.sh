#!/usr/bin/env bash

set -Eeo pipefail

cd "$RAPIDS_HOME"

update-environment-variables;

build_all() {
    echo -e "\n\n\n\n# Building rapids projects"                                       \
    && print_heading "librmm"       && build_cpp "$RMM_HOME" ""                        \
    && print_heading "libnvstrings" && build_cpp "$CUDF_HOME" "nvstrings"              \
    && print_heading "libcudf"      && build_cpp "$CUDF_HOME" "cudf"                   \
    && print_heading "libcugraph"   && build_cpp "$CUGRAPH_HOME" ""                    \
    && print_heading "rmm"          && build_python "$RMM_HOME/python" --inplace       \
    && print_heading "nvstrings"    && build_python "$CUDF_HOME/python/nvstrings"      \
    && print_heading "cudf"         && build_python "$CUDF_HOME/python/cudf" --inplace \
    && print_heading "cugraph"      && build_python "$CUGRAPH_HOME/python" --inplace   \
    ;
}

build_cpp() {
    cd "$1"
    BUILD_TARGETS="${2:-}";
    if [ -n "$BUILD_TARGETS" ] && [ "$BUILD_TESTS" = "ON" ]; then
        BUILD_TARGETS="$BUILD_TARGETS build_tests_$BUILD_TARGETS";
    fi
    cpp-exec-cmake                                   \
 && ninja -C "$(find-cpp-build-home)" $BUILD_TARGETS \
 && build_cpp_launch_json "$(find-cpp-home)"         \
 ;
}

build_python() {
    CC_="$CC"
    JOBS=$(nproc --ignore=2)
    [ "$USE_CCACHE" == "YES" ] && CC_="$(which ccache) $CC";
    cd "$1"                                                \
 && env CC="$CC_" python setup.py build_ext -j$JOBS ${2:-} \
 && env CC="$CC_" python setup.py install                  \
 && rm -rf ./*.egg-info                                    \
 ;
}

print_heading() {
    echo -e "\n\n\n\n################\n\n\n\n# Build $1 \n\n\n\n################\n\n\n\n"
}

join_list_contents() {
    local IFS='' delim=$1; shift; echo -n "$1"; shift; echo -n "${*/#/$delim}";
}

build_cpp_launch_json() {
    mkdir -p "$1/.vscode";
    BUILD_DIR=`cpp-build-dir $1`;
    TESTS_DIR="$1/build/debug/gtests";
    PROJECT_NAME="${1#$RAPIDS_HOME/}";
    TEST_NAMES=$(ls $TESTS_DIR 2>/dev/null || echo "");
    TEST_NAMES=$(echo \"$(join_list_contents '","' $TEST_NAMES)\");
    cat << EOF > "$1/.vscode/launch.json"
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "$PROJECT_NAME",
            "type": "cppdbg",
            "request": "launch",
            "stopAtEntry": false,
            "externalConsole": false,
            "cwd": "$1",
            "envFile": "\${workspaceFolder:compose}/.env",
            "MIMode": "gdb", "miDebuggerPath": "/usr/local/cuda/bin/cuda-gdb",
            "program": "$TESTS_DIR/\${input:TEST_NAME}",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ],
            "environment": [{
                "name": "LIBCUDF_INCLUDE_DIR",
                "value": "$1/build/include"
            }]
        },
    ],
    "inputs": [
        {
            "id": "TEST_NAME",
            "type": "pickString",
            "description": "Please select a test to run",
            "options": [$TEST_NAMES]
        }
    ]
}
EOF
}

build_all
