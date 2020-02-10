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

cpp-exec-cmake() {
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
        -DPARALLEL_LEVEL=$(nproc --ignore=2)
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
    env JOBS=$(nproc --ignore=2)                                          \
        PARALLEL_LEVEL=$(nproc --ignore=2)                                \
        cmake $D_CMAKE_ARGS "$PROJECT_CPP_HOME"                           \
     && fix-nvcc-clangd-compile-commands "$PROJECT_CPP_HOME" "$BUILD_DIR" \
    ;
    export CONDA_PREFIX="$CONDA_PREFIX_"; unset CONDA_PREFIX_;
    cd -;
}

export -f cpp-exec-cmake;

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
