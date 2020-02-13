#!/usr/bin/env bash

set -Eeo pipefail

cd "$RAPIDS_HOME"

update-environment-variables;

build_all() {

    [ "$BUILD_CUML" == "YES" ] && should_build_cuml="YES" || should_build_cuml="NO";
    [ "$BUILD_CUGRAPH" == "YES" ] && should_build_cugraph="YES" || should_build_cugraph="NO";

    [ "$BUILD_CUGRAPH" == "YES" ] \
    || [ "$BUILD_CUML" == "YES" ] \
    || [ "$BUILD_CUDF" == "YES" ] && should_build_cudf="YES" || should_build_cudf="NO";

    [ "$BUILD_CUGRAPH" == "YES" ] \
    || [ "$BUILD_CUML" == "YES" ] \
    || [ "$BUILD_CUDF" == "YES" ] \
    || [ "$BUILD_RMM"  == "YES" ] && should_build_rmm="YES" || should_build_rmm="NO";

    print_heading "\
RAPIDS projects: \
RMM: $should_build_rmm, \
cuDF: $should_build_cudf, \
cuML: $should_build_cuml, \
cuGraph: $should_build_cugraph"

    [ "$should_build_rmm"     == "YES" ] && print_heading "librmm"       && build_cpp "$RMM_HOME"                           ;
    [ "$should_build_cudf"    == "YES" ] && print_heading "libnvstrings" && build_cpp "$CUDF_HOME/cpp" "nvstrings"          ;
    [ "$should_build_cudf"    == "YES" ] && print_heading "libcudf"      && build_cpp "$CUDF_HOME/cpp" "cudf"               ;
    [ "$should_build_cuml"    == "YES" ] && print_heading "libcuml"      && build_cpp "$CUML_HOME/cpp"                      ;
    [ "$should_build_cugraph" == "YES" ] && print_heading "libcugraph"   && build_cpp "$CUGRAPH_HOME/cpp" ""                ;
    [ "$should_build_rmm"     == "YES" ] && print_heading "rmm"          && build_python "$RMM_HOME/python" --inplace       ;
    [ "$should_build_cudf"    == "YES" ] && print_heading "nvstrings"    && build_python "$CUDF_HOME/python/nvstrings"      ;
    [ "$should_build_cudf"    == "YES" ] && print_heading "cudf"         && build_python "$CUDF_HOME/python/cudf" --inplace ;
    [ "$should_build_cudf"    == "YES" ] && print_heading "dask_cudf"    && build_python "$CUDF_HOME/python/dask_cudf"      ;
    [ "$should_build_cuml"    == "YES" ] && print_heading "cuml"         && build_python "$CUML_HOME/python" --inplace      ;
    [ "$should_build_cugraph" == "YES" ] && print_heading "cugraph"      && build_python "$CUGRAPH_HOME/python" --inplace   ;
}

build_cpp() {
    cd "$1" && cd "$(find-cpp-home)"
    BUILD_TARGETS="${2:-}";
    BUILD_DIR_PATH="$(find-cpp-build-home)"
    if [ -n "$BUILD_TARGETS" ] && [ "$BUILD_TESTS" = "ON" ]; then
        BUILD_TARGETS="$BUILD_TARGETS build_tests_$BUILD_TARGETS";
    fi
    cpp-exec-cmake $1;
    if [ -f "$BUILD_DIR_PATH/build.ninja" ]; then
        ninja -C "$BUILD_DIR_PATH" $BUILD_TARGETS;
    else
        make  -C "$BUILD_DIR_PATH" $BUILD_TARGETS -j$(nproc --ignore=2);
    fi
    build_cpp_launch_json "$(find-cpp-home)";
}

build_python() {
    cd "$1";
    CC_="$CC";
    ARGS="${2:-}";
    JOBS=$(nproc --ignore=2);
    [ "$ARGS" != "--inplace" ] && rm -rf ./build;
    [ "$USE_CCACHE" == "YES" ] && CC_="$(which ccache) $CC";
    env CC="$CC_" python setup.py build_ext -j$JOBS ${ARGS};
    env CC="$CC_" python setup.py install;
    rm -rf ./*.egg-info;
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
