#!/usr/bin/env bash

set -Eeuo pipefail

cd "$RAPIDS_HOME"

update-environment-variables;

export JOBS=$(nproc --ignore=2)
export PARALLEL_LEVEL=$JOBS

D_CMAKE_ARGS="\
    -GNinja
    -DGPU_ARCHS=
    -DUSE_CCACHE=1
    -DCONDA_BUILD=0
    -DCMAKE_CXX11_ABI=ON
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    -DBUILD_TESTS=${BUILD_TESTS:-OFF}
    -DCMAKE_SYSTEM_PREFIX_PATH=${COMPOSE_HOME}/etc/conda/envs/rapids
    -DBUILD_BENCHMARKS=${BUILD_BENCHMARKS:-OFF}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release}
    -DRMM_LIBRARY=${RMM_LIBRARY}
    -DCUDF_LIBRARY=${CUDF_LIBRARY}
    -DCUGRAPH_LIBRARY=${CUGRAPH_LIBRARY}
    -DNVSTRINGS_LIBRARY=${NVSTRINGS_LIBRARY}
    -DNVCATEGORY_LIBRARY=${NVCATEGORY_LIBRARY}
    -DNVTEXT_LIBRARY=${NVTEXT_LIBRARY}
    -DRMM_INCLUDE=${RMM_INCLUDE}
    -DCUDF_INCLUDE=${CUDF_INCLUDE}
    -DDLPACK_INCLUDE=${COMPOSE_INCLUDE}
    -DNVSTRINGS_INCLUDE=${NVSTRINGS_INCLUDE}
    -DCUGRAPH_INCLUDE=${CUGRAPH_INCLUDE}"

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
    cpp-exec-cmake \
 && ninja -C "$(find-cpp-build-home)" $BUILD_TARGETS \
 && build_cpp_launch_json "$(find-cpp-home)"
}

build_python() {
    cd "$1"                                      \
 && python setup.py build_ext -j $(nproc --ignore=2) ${2:-} \
 && python setup.py install                      \
 && rm -rf ./*.egg-info
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
            ]
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
