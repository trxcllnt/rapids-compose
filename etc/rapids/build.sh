#!/usr/bin/env bash

set -Eeuo pipefail

cd "$RAPIDS_HOME"

update-environment-variables;

export JOBS=$(nproc)
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
    && print_heading "libnvstrings" && build_cpp "$CUDF_HOME/cpp" "nvstrings"          \
    && print_heading "libcudf"      && build_cpp "$CUDF_HOME/cpp" "cudf"               \
    && print_heading "libcugraph"   && build_cpp "$CUGRAPH_HOME/cpp" ""                \
    && print_heading "rmm"          && build_python "$RMM_HOME/python" --inplace       \
    && print_heading "nvstrings"    && build_python "$CUDF_HOME/python/nvstrings"      \
    && print_heading "cudf"         && build_python "$CUDF_HOME/python/cudf" --inplace \
    && print_heading "cugraph"      && build_python "$CUGRAPH_HOME/python" --inplace   \
    ;
}

build_cpp() {
    BUILD_TARGETS="$2";
    CPP_ROOT=$(realpath "$1");
    BUILD_DIR="$CPP_ROOT/`cpp-build-dir $CPP_ROOT`";
    INSTALL_PATH="$CPP_ROOT/build/$(cpp-build-type)";
    if [ -n "$BUILD_TARGETS" ] && [ "$BUILD_TESTS" = "ON" ]; then
        BUILD_TARGETS="$BUILD_TARGETS build_tests_$BUILD_TARGETS";
    fi
    mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"  \
 && cmake $D_CMAKE_ARGS -DCMAKE_INSTALL_PREFIX="$INSTALL_PATH" "$CPP_ROOT" \
 && fix_nvcc_clangd_compile_commands "$CPP_ROOT" "$BUILD_DIR" \
 && ninja -C "$BUILD_DIR" $BUILD_TARGETS \
 && build_cpp_launch_json "$CPP_ROOT"
}

build_python() {
    cd "$1"                                      \
 && python setup.py build_ext -j $(nproc) ${2:-} \
 && python setup.py install                      \
 && rm -rf ./*.egg-info
}

fix_nvcc_clangd_compile_commands() {
    ###
    # Make a few modifications to the compile_commands.json file
    # produced by CMake. This file is used by clangd to provide fast
    # and smart intellisense, but `clang-10` doesn't yet support all
    # the nvcc compilation options. This block translates or removes
    # unsupported options, so `clangd` has an easier time producing
    # usable intellisense results.
    ###
    CC_JSON="$2/compile_commands.json";
    CC_JSON_LINK="$1/compile_commands.json";
    CC_JSON_CLANGD="$2/compile_commands.clangd.json";
    CLANG_CUDA_OPTIONS="-x cuda --no-cuda-version-check -nocudalib";
    ALLOWED_WARNINGS=$(echo $(echo '
        -Wno-unknown-pragmas
        -Wno-c++17-extensions
        -Wno-unevaluated-expression'));

    # 1. Remove the second compiler invocation following the `&&`
    # 2. Remove unsupported -gencode options
    # 3. Remove unsupported --expt-extended-lambda option
    # 4. Remove unsupported --expt-relaxed-constexpr option
    # 5. Rewrite `-Wall,-Werror` to be `-Wall -Werror`
    # 6. Change `-x cu` to `-x cuda` and add other clang cuda options
    # 7. Add `-I$CUDA_HOME/include` to nvcc invocations
    # 8. Add flags to disable certain warnings for intellisense
    cat "$CC_JSON"                                   \
    | sed -r "s/ &&.*[^\$DEP_FILE]/\",/g"            \
    | sed -r "s/\-gencode\ arch=([^\-])*//g"         \
    | sed -r "s/ --expt-extended-lambda/ /g"         \
    | sed -r "s/ --expt-relaxed-constexpr/ /g"       \
    | sed -r "s/-Wall,-Werror/-Wall -Werror/g"       \
    | sed -r "s/ -x cu / $CLANG_CUDA_OPTIONS /g"     \
    | sed -r "s!nvcc !nvcc -I$CUDA_HOME/include!g"   \
    | sed -r "s/-Werror/-Werror $ALLOWED_WARNINGS/g" \
    > "$CC_JSON_CLANGD"                              ;

    # symlink compile_commands.json to the project root so clangd can find it
    make-symlink "$CC_JSON_CLANGD" "$CC_JSON_LINK";
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
