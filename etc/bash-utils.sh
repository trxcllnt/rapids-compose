#!/usr/bin/env bash

set -Eeo pipefail

find-project-home() {
    PROJECT_HOMES="\
    $RMM_HOME
    $CUDF_HOME
    $CUML_HOME
    $CUGRAPH_HOME
    $NOTEBOOKS_HOME
    $NOTEBOOKS_EXTENDED_HOME";
    for PROJECT_HOME in $PROJECT_HOMES; do
        if [ -n "$(echo "$PWD" | grep "$PROJECT_HOME" - || echo "")" ]; then
            echo "$PROJECT_HOME"; break;
        fi;
    done
}

export -f find-project-home;

find-cpp-home() {
    PROJECT_HOME="$(find-project-home)";
    if [ "$PROJECT_HOME" != "$RMM_HOME" ]; then
        PROJECT_HOME="$PROJECT_HOME/cpp"
    fi;
    echo "$PROJECT_HOME";
}

export -f find-cpp-home;

find-cpp-build-home() {
    echo "$(find-cpp-home)/build/$(cpp-build-type)";
}

export -f find-cpp-build-home;

cpp-build-type() {
    echo "${CMAKE_BUILD_TYPE:-Release}" | tr '[:upper:]' '[:lower:]'
}

export -f cpp-build-type;

cpp-build-dir() {
    cd "$1"
    _BUILD_DIR="$(git branch --show-current)"
    _BUILD_DIR="cuda-$CUDA_SHORT_VERSION/${_BUILD_DIR//\//__}"
    echo "build/$_BUILD_DIR/$(cpp-build-type)"
}

export -f cpp-build-dir;

make-symlink() {
    SRC="$1"; DST="$2";
    CUR=$(readlink "$2" || echo "");
    [ -z "$SRC" ] || [ -z "$DST" ] || \
    [ "$CUR" = "$SRC" ] || ln -f -n -s "$SRC" "$DST"
}

export -f make-symlink;

update-environment-variables() {
    set -a && . "$COMPOSE_HOME/.env" && set +a
    if [ ${CONDA_PREFIX:-""} != "" ]; then
        bash "$CONDA_PREFIX/etc/conda/activate.d/env-vars.sh"
    fi
    unset NVIDIA_VISIBLE_DEVICES
}

export -f update-environment-variables;

configure-cpp() {
    update-environment-variables;
    PROJECT_CPP_HOME="$(find-cpp-home)";
    PROJECT_CPP_HOME="${1:-$PROJECT_CPP_HOME}"
    BUILD_DIR="$PROJECT_CPP_HOME/`cpp-build-dir $PROJECT_CPP_HOME`";
    mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR";
    D_CMAKE_ARGS="\
        -DGPU_ARCHS=
        -DCONDA_BUILD=0
        -DCMAKE_CXX11_ABI=ON
        -DARROW_USE_CCACHE=ON
        -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
        -DBUILD_TESTS=${BUILD_TESTS:-OFF}
        -DBUILD_BENCHMARKS=${BUILD_BENCHMARKS:-OFF}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release}
        -DRMM_LIBRARY=${RMM_LIBRARY}
        -DCUDF_LIBRARY=${CUDF_LIBRARY}
        -DCUML_LIBRARY=${CUML_LIBRARY}
        -DCUGRAPH_LIBRARY=${CUGRAPH_LIBRARY}
        -DNVSTRINGS_LIBRARY=${NVSTRINGS_LIBRARY}
        -DNVCATEGORY_LIBRARY=${NVCATEGORY_LIBRARY}
        -DNVTEXT_LIBRARY=${NVTEXT_LIBRARY}
        -DRMM_INCLUDE=${RMM_INCLUDE}
        -DCUDF_INCLUDE=${CUDF_INCLUDE}
        -DCUML_INCLUDE_DIR=${CUML_INCLUDE}
        -DDLPACK_INCLUDE=${COMPOSE_INCLUDE}
        -DNVSTRINGS_INCLUDE=${NVSTRINGS_INCLUDE}
        -DCUGRAPH_INCLUDE=${CUGRAPH_INCLUDE}
        -DPARALLEL_LEVEL=$PARALLEL_LEVEL
        -DCMAKE_INSTALL_PREFIX=$(find-cpp-build-home)
        -DCMAKE_SYSTEM_PREFIX_PATH=${COMPOSE_HOME}/etc/conda/envs/rapids";

    if [ "$(find-project-home)" == "$CUGRAPH_HOME" ]; then
        D_CMAKE_ARGS="$D_CMAKE_ARGS -GNinja
        -DLIBCYPHERPARSER_INCLUDE=${COMPOSE_HOME}/etc/conda/envs/rapids/include
        -LIBCYPHERPARSER_LIBRARY=${COMPOSE_HOME}/etc/conda/envs/rapids/lib/libcypher-parser.a";

    elif [ "$(find-project-home)" == "$CUML_HOME" ]; then
        D_CMAKE_ARGS="$D_CMAKE_ARGS
        -DWITH_UCX=ON
        -DBUILD_CUML_TESTS=${BUILD_TESTS:-OFF}
        -DBUILD_PRIMS_TESTS=${BUILD_TESTS:-OFF}
        -DBUILD_CUML_MG_TESTS=${BUILD_TESTS:-OFF}
        -DBUILD_CUML_BENCH=${BUILD_BENCHMARKS:-OFF}
        -DBUILD_CUML_PRIMS_BENCH=${BUILD_BENCHMARKS:-OFF}
        -DBLAS_LIBRARIES=${COMPOSE_HOME}/etc/conda/envs/rapids/lib/libblas.so";

    else
        D_CMAKE_ARGS="$D_CMAKE_ARGS -GNinja"
    fi;

    if [ "$USE_CCACHE" == "YES" ]; then
        D_CMAKE_ARGS="$D_CMAKE_ARGS
        -DCMAKE_CXX_COMPILER_LAUNCHER=$(which ccache)
        -DCMAKE_CUDA_COMPILER_LAUNCHER=$(which ccache)";
    fi

    export CONDA_PREFIX_="$CONDA_PREFIX"; unset CONDA_PREFIX;
    env JOBS=$PARALLEL_LEVEL                                              \
        PARALLEL_LEVEL=$PARALLEL_LEVEL                                    \
        cmake $D_CMAKE_ARGS "$PROJECT_CPP_HOME"                           \
     && fix-nvcc-clangd-compile-commands "$PROJECT_CPP_HOME" "$BUILD_DIR" \
    ;
    export CONDA_PREFIX="$CONDA_PREFIX_"; unset CONDA_PREFIX_;
    cd -;
}

export -f configure-cpp;

build-cpp() {
    update-environment-variables;
    cd "$1" && cd "$(find-cpp-home)"
    BUILD_TARGETS="${2:-}";
    BUILD_DIR_PATH="$(find-cpp-build-home)"
    if [ -n "$BUILD_TARGETS" ] && [ "$BUILD_TESTS" = "ON" ]; then
        BUILD_TARGETS="$BUILD_TARGETS build_tests_$BUILD_TARGETS";
    fi
    configure-cpp $1;
    if [ -f "$BUILD_DIR_PATH/build.ninja" ]; then
        ninja -C "$BUILD_DIR_PATH" $BUILD_TARGETS -j$PARALLEL_LEVEL;
    else
        make  -C "$BUILD_DIR_PATH" $BUILD_TARGETS -j$PARALLEL_LEVEL;
    fi
    create-cpp-launch-json "$(find-cpp-home)";
}

export -f build-cpp;

build-python() {
    cd "$1";
    CC_="$CC"
    ARGS=${@:2};
    [ "$ARGS" != "--inplace" ] && rm -rf ./build;
    [ "$USE_CCACHE" == "YES" ] && CC_="$(which ccache) $CC";
    env CC="$CC_" python setup.py build_ext -j$PARALLEL_LEVEL ${ARGS};
    rm -rf ./*.egg-info;
}

export -f build-python;

fix-nvcc-clangd-compile-commands() {
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
    # todo: should define `-D__CUDACC__` here?
    CLANG_NVCC_OPTIONS="-I$CUDA_HOME/include";
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
    | sed -r "s!nvcc !nvcc $CLANG_NVCC_OPTIONS!g"    \
    | sed -r "s/-Werror/-Werror $ALLOWED_WARNINGS/g" \
    > "$CC_JSON_CLANGD"                              ;

    # symlink compile_commands.json to the project root so clangd can find it
    make-symlink "$CC_JSON_CLANGD" "$CC_JSON_LINK";
}

export -f fix-nvcc-clangd-compile-commands;

join_list_contents() {
    local IFS='' delim=$1; shift; echo -n "$1"; shift; echo -n "${*/#/$delim}";
}

create-cpp-launch-json() {
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
                "value": "$CUDF_HOME/cpp/$(cpp-build-dir $CUDF_HOME)/include"
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

export -f create-cpp-launch-json;

build-rapids() {

    cd "$RAPIDS_HOME";

    update-environment-variables;

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

    [ "$should_build_rmm"     == "YES" ] && print_heading "librmm"       && build-rmm-cpp           ;
    [ "$should_build_cudf"    == "YES" ] && print_heading "libnvstrings" && build-nvstrings-cpp     ;
    [ "$should_build_cudf"    == "YES" ] && print_heading "libcudf"      && build-cudf-cpp          ;
    [ "$should_build_cuml"    == "YES" ] && print_heading "libcuml"      && build-cuml-cpp          ;
    [ "$should_build_cugraph" == "YES" ] && print_heading "libcugraph"   && build-cugraph-cpp       ;
    [ "$should_build_rmm"     == "YES" ] && print_heading "rmm"          && build-rmm-python        ;
    [ "$should_build_cudf"    == "YES" ] && print_heading "nvstrings"    && build-nvstrings-python  ;
    [ "$should_build_cudf"    == "YES" ] && print_heading "cudf"         && build-cudf-python       ;
    [ "$should_build_cuml"    == "YES" ] && print_heading "cuml"         && build-cuml-python       ;
    [ "$should_build_cugraph" == "YES" ] && print_heading "cugraph"      && build-cugraph-python    ;
}

export -f build-rapids;

clean-rapids() {

    cd "$RAPIDS_HOME"

    update-environment-variables;

    # If build clean, delete all build and runtime assets and caches
    rm -rf "$RMM_HOME/`cpp-build-dir $RMM_HOME`" \
        "$CUDF_HOME/cpp/`cpp-build-dir $CUDF_HOME`" \
        "$CUML_HOME/cpp/`cpp-build-dir $CUML_HOME`" \
        "$CUGRAPH_HOME/cpp/`cpp-build-dir $CUGRAPH_HOME`" \
        "$RMM_HOME/python/dist" \
        "$RMM_HOME/python/build" \
        "$CUDF_HOME/python/.hypothesis" \
        "$CUDF_HOME/python/cudf/dist" \
        "$CUDF_HOME/python/cudf/build" \
        "$CUDF_HOME/python/cudf/.pytest_cache" \
        "$CUDF_HOME/python/nvstrings/dist" \
        "$CUDF_HOME/python/nvstrings/build" \
        "$CUDF_HOME/python/nvstrings/.pytest_cache" \
        "$CUDF_HOME/python/dask_cudf/dist" \
        "$CUDF_HOME/python/dask_cudf/build" \
        "$CUDF_HOME/python/dask_cudf/.pytest_cache" \
        "$CUML_HOME/python/dist" \
        "$CUML_HOME/python/build" \
        "$CUML_HOME/python/.hypothesis" \
        "$CUML_HOME/python/.pytest_cache" \
        "$CUML_HOME/python/external_repositories" \
        "$CUGRAPH_HOME/python/dist" \
        "$CUGRAPH_HOME/python/build" \
        "$CUGRAPH_HOME/python/.hypothesis" \
        "$CUGRAPH_HOME/python/.pytest_cache" \
    \
    && find "$RMM_HOME" -type f -name '*.pyc' -delete \
    && find "$CUDF_HOME" -type f -name '*.pyc' -delete \
    && find "$CUML_HOME" -type f -name '*.pyc' -delete \
    && find "$CUGRAPH_HOME" -type f -name '*.pyc' -delete \
    && find "$RMM_HOME" -type d -name '__pycache__' -delete \
    && find "$CUDF_HOME" -type d -name '__pycache__' -delete \
    && find "$CUML_HOME" -type d -name '__pycache__' -delete \
    && find "$CUGRAPH_HOME" -type d -name '__pycache__' -delete \
    \
    && find "$CUML_HOME/python/cuml" -type f -name '*.so' -delete \
    && find "$CUML_HOME/python/cuml" -type f -name '*.cpp' -delete \
    && find "$CUGRAPH_HOME/python/cugraph" -type f -name '*.so' -delete \
    && find "$CUGRAPH_HOME/python/cugraph" -type f -name '*.cpp' -delete \
    && find "$CUDF_HOME/python/cudf/cudf" -type f -name '*.so' -delete \
    && find "$CUDF_HOME/python/cudf/cudf" -type f -name '*.cpp' -delete \
    \
    && find "$RMM_HOME" -type d -name '.clangd' -print0 | xargs -0 -I {} /bin/rm -rf "{}" \
    && find "$CUDF_HOME" -type d -name '.clangd' -print0 | xargs -0 -I {} /bin/rm -rf "{}" \
    && find "$CUML_HOME" -type d -name '.clangd' -print0 | xargs -0 -I {} /bin/rm -rf "{}" \
    && find "$CUGRAPH_HOME" -type d -name '.clangd' -print0 | xargs -0 -I {} /bin/rm -rf "{}" \
    ;
}

export -f clean-rapids;

lint-rapids() {
    bash "$COMPOSE_HOME/etc/rapids/lint.sh" || true;
}

export -f lint-rapids;

build-rmm-cpp() {
    build-cpp "$RMM_HOME";
}

export -f build-rmm-cpp;

build-nvstrings-cpp() {
    build-cpp "$CUDF_HOME/cpp" "nvstrings";
}

export -f build-nvstrings-cpp;

build-cudf-cpp() {
    build-cpp "$CUDF_HOME/cpp" "cudf";
}

export -f build-cudf-cpp;

build-cuml-cpp() {
    build-cpp "$CUML_HOME/cpp";
}

export -f build-cuml-cpp;

build-cugraph-cpp() {
    build-cpp "$CUGRAPH_HOME/cpp";
}

export -f build-cugraph-cpp;

build-rmm-python() {
    build-python "$RMM_HOME/python" --inplace;
}

export -f build-rmm-python;

build-nvstrings-python() {
    build-python "$CUDF_HOME/python/nvstrings" \
    --library-dir="$NVSTRINGS_ROOT"            \
    --build-lib="$CUDF_HOME/python/nvstrings"  ;
}

export -f build-nvstrings-python;

build-cudf-python() {
    build-python "$CUDF_HOME/python/cudf" --inplace;
}

export -f build-cudf-python;

build-cuml-python() {
    build-python "$CUML_HOME/python" --inplace;
}

export -f build-cuml-python;

build-cugraph-python() {
    build-python "$CUGRAPH_HOME/python" --inplace;
}

export -f build-cugraph-python;


print_heading() {
    echo -e "\n\n\n\n################\n\n\n\n# Build $1 \n\n\n\n################\n\n\n\n"
}
