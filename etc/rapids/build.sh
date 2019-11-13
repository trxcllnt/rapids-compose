#!/usr/bin/env bash

set -e
set -x

cd "$RAPIDS_HOME"

D_CMAKE_ARGS="\
    -GNinja
    -DGPU_ARCHS=
    -DUSE_CCACHE=1
    -DCONDA_BUILD=0
    -DCMAKE_CXX11_ABI=ON
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    -DBUILD_TESTS=${BUILD_TESTS:-OFF}
    -DCMAKE_INSTALL_PREFIX=${CONDA_PREFIX}
    -DCMAKE_SYSTEM_PREFIX_PATH=${CONDA_PREFIX}
    -DBUILD_BENCHMARKS=${BUILD_BENCHMARKS:-OFF}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release}
    -DCONDA_LINK_DIRS=$RAPIDS_HOME/compose/etc/conda/envs/rapids/lib
    -DCONDA_INCLUDE_DIRS=$RAPIDS_HOME/compose/etc/conda/envs/rapids/include"

_build_all() {
    # This gets around the cudf CMakeList.txt's new "Conda environment detected"
    # feature. This feature adds CONDA_PREFIX to the INCLUDE_DIRS and LINK_DIRS
    # lists, and causes g++ to relink all the shared objects when the conda env
    # changes. This leads to the notebooks container recompiling all the C++
    # artifacts when nothing material has changed since they were built by the
    # rapids container.
    unset CONDA_BUILD
    unset CONDA_PREFIX

    echo -e "\n\n\n\n# Building rapids projects" \
    && _print_heading "librmm"       && _build_cpp "$RMM_HOME" \
    && _print_heading "libcudf"      && _build_cpp "$CUDF_HOME/cpp" \
    && _print_heading "libcugraph"   && _build_cpp "$CUGRAPH_HOME/cpp" \
    && _print_heading "rmm"          && _build_python "$RMM_HOME/python" --inplace \
    && _print_heading "nvstrings"    && _build_python "$CUDF_HOME/python/nvstrings" \
    && _print_heading "cudf"         && _build_python "$CUDF_HOME/python/cudf" --inplace \
    && _print_heading "dask_cudf"    && _build_python "$CUDF_HOME/python/dask_cudf" --inplace \
    && _print_heading "cugraph"      && _build_python "$CUGRAPH_HOME/python" --inplace \
    ;
}

_fix_nvcc_clangd_compile_commands() {
    ###
    # Make a few small modifications to the compile_commands.json file
    # produced by CMake. This file is used by clangd to provide fast
    # and smart intellisense, but `clang-10` doesn't yet support all
    # the nvcc compilation options. This block translates or removes
    # unsupported options, so `clangd` has an easier time producing
    # usable intellisense results.
    # 
    # 1. Remove the second compiler invocation following the `&&`
    # 2. Remove unsupported -gencode options
    # 3. Remove unsupported --expt-extended-lambda option
    # 4. Remove unsupported --expt-relaxed-constexpr option
    # 5. Rewrite `-Wall,-Werror` to be `-Wall -Werror`
    # 6. Change `-x cu` to `-x cuda` and add other clang cuda options
    # 7. Add `-I$CUDA_HOME/include` to nvcc invocations
    # 8. Add flags to disable certain warnings for intellisense
    ###
    TOLERATED_WARNINGS="\
        -Wno-unknown-pragmas \
        -Wno-c++17-extensions \
        -Wno-unevaluated-expression";
    ALLOWED_WARNINGS="$(echo $TOLERATED_WARNINGS)";
    CLANG_CUDA_OPTIONS="-x cuda --no-cuda-version-check -nocudalib";
    cat "$1"                                         \
    | sed -r "s/ &&.*[^\$DEP_FILE]/\",/g"            \
    | sed -r "s/\-gencode\ arch=([^\-])*//g"         \
    | sed -r "s/ --expt-extended-lambda/ /g"         \
    | sed -r "s/ --expt-relaxed-constexpr/ /g"       \
    | sed -r "s/-Wall,-Werror/-Wall -Werror/g"       \
    | sed -r "s/ -x cu / $CLANG_CUDA_OPTIONS /g"     \
    | sed -r "s!nvcc !nvcc -I$CUDA_HOME/include!g"   \
    | sed -r "s/-Werror/-Werror $ALLOWED_WARNINGS/g" \
    > "$1.tmp" && mv "$1.tmp" "$1"
}

_build_cpp() {
    cd "$1" && mkdir -p "$1/build" && cd "$1/build"                    \
 && env JOBS=$(nproc) PARALLEL_LEVEL=$(nproc) cmake $D_CMAKE_ARGS ..   \
 && _fix_nvcc_clangd_compile_commands "$1/build/compile_commands.json" \
 && env JOBS=$(nproc) PARALLEL_LEVEL=$(nproc) ninja -j$(nproc) install \
 && _build_cpp_launch_json "$1"
}

_build_python() {
    cd "$1" \
 && python setup.py build_ext -j $(nproc) $2 \
 && python setup.py install \
 && rm -rf *.egg-info
}

_print_heading() {
    echo -e "\n\n\n\n################\n\n\n\n# Build $1 \n\n\n\n################\n\n\n\n"
}

_join_list_contents() {
    local IFS='' delim=$1; shift; echo -n "$1"; shift; echo -n "${*/#/$delim}";
}

_build_cpp_launch_json() {
    mkdir -p "$1/.vscode";
    DEBUG_NAME="${1#$RAPIDS_HOME/}"
    TEST_NAMES=$(echo \"$(_join_list_contents '","' $(ls $1/build/gtests))\");
    cat << EOF > "$1/.vscode/launch.json"
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "$DEBUG_NAME",
            "type": "cppdbg",
            "request": "launch",
            "stopAtEntry": false,
            "externalConsole": false,
            "cwd": "$1",
            "envFile": "\${workspaceFolder:compose}/.env",
            "MIMode": "gdb", "miDebuggerPath": "/usr/local/cuda/bin/cuda-gdb",
            "program": "$1/build/gtests/\${input:TEST_NAME}",
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

_build_all
