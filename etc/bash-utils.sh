#!/usr/bin/env bash

set -Eeo pipefail

############
# 
# This file defines and exports a set of helpful bash functions.
# 
# Before executing, each of these functions will read the .env file in your
# rapids-compose repo. It is safe to edit the .env file while the container
# is running and re-execute any of these commands. The edited value will be
# reflected in the command execution.
# 
# Note: The (✝) character at the beginning of a command's description denotes
# the command can be run from any directory.
# 
###
# Project-wide commands:
#
# build-rapids - (✝) Build each enabled RAPIDS project from source in the order
#                    determined by their dependence on each other. For example,
#                    RMM will be built before cuDF because cuDF depends on RMM.
# clean-rapids - (✝) Remove build artifacts for each enabled RAPIDS project
# lint-rapids  - (✝) Lint/fix Cython/Python for each enabled RAPIDS project
#
###
# Commands to build each project separately:
# 
# build-rmm-cpp          - (✝) Build the librmm C++ library
# build-cudf-cpp         - (✝) Build the libcudf C++ library
# build-cuml-cpp         - (✝) Build the libcuml C++ library
# build-cugraph-cpp      - (✝) Build the libcugraph C++ library
# 
# build-rmm-python       - (✝) Build the rmm Cython bindings
# build-cudf-python      - (✝) Build the cudf Cython bindings
# build-cuml-python      - (✝) Build the cuml Cython bindings
# build-cugraph-python   - (✝) Build the cugraph Cython bindings
# 
###
# Commands to clean each project separately:
# 
# clean-rmm-cpp          - (✝) Clean the librmm C++ build folder for the current git branch
# clean-cudf-cpp         - (✝) Clean the libcudf C++ build folder for the current git branch
# clean-cuml-cpp         - (✝) Clean the libcuml C++ build folder for the current git branch
# clean-cugraph-cpp      - (✝) Clean the libcugraph C++ build folder for the current git branch
# 
# clean-rmm-python       - (✝) Clean the rmm Cython build assets
# clean-cudf-python      - (✝) Clean the cudf Cython build assets
# clean-cuml-python      - (✝) Clean the cuml Cython build assets
# clean-cugraph-python   - (✝) Clean the cugraph Cython build assets
# 
###
# Commands to lint each Python project separately:
# 
# lint-rmm-python        - (✝) Lint/fix the rmm Cython and Python source files
# lint-cudf-python       - (✝) Lint/fix the cudf Cython and Python source files
# lint-cuml-python       - (✝) Lint/fix the cuml Cython and Python source files
# lint-cugraph-python    - (✝) Lint/fix the cugraph Cython and Python source files
# 
###
# Misc
# 
# cpp-build-type               - (✝) Function to print the C++ CMAKE_BUILD_TYPE
# cpp-build-dir                - (✝) Function to print the C++ build path relative to a project's C++ source directory
# make-symlink                 - (✝) Function to safely make non-dereferenced symlinks
# update-environment-variables - (✝) Reads the rapids-compose .env file and updates the current shell with the latest values
###

should-build-rmm() {
    update-environment-variables;
    $(should-build-cudf) || [ "$BUILD_RMM" == "YES" ] && echo true || echo false;
}

export -f should-build-rmm;

should-build-cudf() {
    update-environment-variables;
    $(should-build-cuml) || $(should-build-cugraph) || [ "$BUILD_CUDF" == "YES" ] && echo true || echo false;
}

export -f should-build-cudf;

should-build-cuml() {
    update-environment-variables;
    [ "$BUILD_CUML" == "YES" ] && echo true || echo false;
}

export -f should-build-cuml;

should-build-cugraph() {
    update-environment-variables;
    [ "$BUILD_CUGRAPH" == "YES" ] && echo true || echo false;
}

export -f should-build-cugraph;

build-rapids() {
    print-heading "\
Building RAPIDS projects: \
RMM: $(should-build-rmm), \
cuDF: $(should-build-cudf), \
cuML: $(should-build-cuml), \
cuGraph: $(should-build-cugraph)" \
    && build-rmm-cpp \
    && build-cudf-cpp \
    && build-cuml-cpp \
    && build-cugraph-cpp \
    && build-rmm-python \
    && build-cudf-python \
    && build-cuml-python \
    && build-cugraph-python \
    ;
}

export -f build-rapids;

clean-rapids() {
    print-heading "\
Cleaning RAPIDS projects: \
RMM: $(should-build-rmm), \
cuDF: $(should-build-cudf), \
cuML: $(should-build-cuml), \
cuGraph: $(should-build-cugraph)" \
    && clean-rmm-cpp \
    && clean-cudf-cpp \
    && clean-cuml-cpp \
    && clean-cugraph-cpp \
    && clean-rmm-python \
    && clean-cudf-python \
    && clean-cuml-python \
    && clean-cugraph-python \
    ;
}

export -f clean-rapids;

lint-rapids() {
    print-heading "\
Linting RAPIDS projects: \
RMM: $(should-build-rmm), \
cuDF: $(should-build-cudf)" \
    && lint-rmm-python \
    && lint-cudf-python \
    ;
    # && lint-cuml-python \
    # && lint-cugraph-python \
    # ;
}

export -f lint-rapids;

build-rmm-cpp() {
    if [ $(should-build-rmm) == true ];
    then print-heading "Building librmm" && build-cpp "$RMM_HOME";
    else echo "Skipping build-rmm-cpp because BUILD_RMM != YES in your .env file"; fi;
}

export -f build-rmm-cpp;

build-cudf-cpp() {
    if [ $(should-build-cudf) == true ];
    then print-heading "Building libnvstrings" && build-cpp "$CUDF_HOME/cpp" "nvstrings" \
      && print-heading "Building libcudf" && build-cpp "$CUDF_HOME/cpp" "cudf";
    else echo "Skipping build-cudf-cpp because BUILD_CUDF != YES in your .env file"; fi;
}

export -f build-cudf-cpp;

build-cuml-cpp() {
    if [ $(should-build-cuml) == true ];
    then print-heading "Building libcuml" && build-cpp "$CUML_HOME/cpp";
    else echo "Skipping build-cuml-cpp because BUILD_CUML != YES in your .env file"; fi;
}

export -f build-cuml-cpp;

build-cugraph-cpp() {
    if [ $(should-build-cugraph) == true ];
    then print-heading "Building libcugraph" && build-cpp "$CUGRAPH_HOME/cpp";
    else echo "Skipping build-cugraph-cpp because BUILD_CUGRAPH != YES in your .env file"; fi;
}

export -f build-cugraph-cpp;

build-rmm-python() {
    if [ $(should-build-rmm) == true ];
    then print-heading "Building rmm" && build-python "$RMM_HOME/python" --inplace;
    else echo "Skipping build-rmm-python because BUILD_RMM != YES in your .env file"; fi;
}

export -f build-rmm-python;

build-nvstrings-python() {
    if [ $(should-build-cudf) == true ]; then

        print-heading "Building nvstrings";
        nvstrings_py_dir="$CUDF_HOME/python/nvstrings";
        cfile=$(find "$nvstrings_py_dir/build" -type f -name 'CMakeCache.txt' 2> /dev/null | head -n1);
        [ -z "$(grep $CUDA_VERSION "$cfile" 2> /dev/null)" ] && rm -rf "$nvstrings_py_dir/build";

        build-python "$nvstrings_py_dir" \
            --build-lib="$nvstrings_py_dir" \
            --library-dir="$NVSTRINGS_ROOT" ;

    else echo "Skipping build-nvstrings-python because BUILD_CUDF != YES in your .env file"; fi;
}

export -f build-nvstrings-python;

build-cudf-python() {
    if [ $(should-build-cudf) == true ];
    then build-nvstrings-python \
      && print-heading "Building cudf" && build-python "$CUDF_HOME/python/cudf" --inplace;
    else echo "Skipping build-cudf-python because BUILD_CUDF != YES in your .env file"; fi;
}

export -f build-cudf-python;

build-cuml-python() {
    if [ $(should-build-cuml) == true ];
    then print-heading "Building cuml" && build-python "$CUML_HOME/python" --inplace;
    else echo "Skipping build-cuml-python because BUILD_CUML != YES in your .env file"; fi;
}

export -f build-cuml-python;

build-cugraph-python() {
    if [ $(should-build-cugraph) == true ];
    then print-heading "Building cugraph" && build-python "$CUGRAPH_HOME/python" --inplace;
    else echo "Skipping build-cugraph-python because BUILD_CUGRAPH != YES in your .env file"; fi;
}

export -f build-cugraph-python;

clean-rmm-cpp() {
    if [ $(should-build-rmm) == true ]; then
        print-heading "Cleaning librmm";
        rm -rf "$RMM_ROOT_ABS";
        find "$RMM_HOME" -type d -name '.clangd' -print0 | xargs -0 -I {} /bin/rm -rf "{}";
    else echo "Skipping clean-rmm-cpp because BUILD_RMM != YES in your .env file"; fi;
}

export -f clean-rmm-cpp;

clean-cudf-cpp() {
    if [ $(should-build-cudf) == true ]; then
        print-heading "Cleaning libcudf";
        rm -rf "$CUDF_ROOT_ABS";
        find "$CUDF_HOME" -type d -name '.clangd' -print0 | xargs -0 -I {} /bin/rm -rf "{}";
    else echo "Skipping clean-cudf-cpp because BUILD_CUDF != YES in your .env file"; fi;
}

export -f clean-cudf-cpp;

clean-cuml-cpp() {
    if [ $(should-build-cuml) == true ]; then
        print-heading "Cleaning libcuml";
        rm -rf "$CUML_ROOT_ABS";
        find "$CUML_HOME" -type d -name '.clangd' -print0 | xargs -0 -I {} /bin/rm -rf "{}";
    else echo "Skipping clean-cuml-cpp because BUILD_CUML != YES in your .env file"; fi;
}

export -f clean-cuml-cpp;

clean-cugraph-cpp() {
    if [ $(should-build-cugraph) == true ]; then
        print-heading "Cleaning libcugraph";
        rm -rf "$CUGRAPH_ROOT_ABS";
        find "$CUGRAPH_HOME" -type d -name '.clangd' -print0 | xargs -0 -I {} /bin/rm -rf "{}";
    else echo "Skipping clean-cugraph-cpp because BUILD_CUGRAPH != YES in your .env file"; fi;
}

export -f clean-cugraph-cpp;

clean-rmm-python() {
    if [ $(should-build-rmm) == true ]; then
        print-heading "Cleaning rmm";
        rm -rf "$RMM_HOME/python/dist" \
               "$RMM_HOME/python/build";
        find "$RMM_HOME" -type f -name '*.pyc' -delete;
        find "$RMM_HOME" -type d -name '__pycache__' -delete;
    else echo "Skipping clean-rmm-python because BUILD_RMM != YES in your .env file"; fi;
}

export -f clean-rmm-python;

clean-cudf-python() {
    if [ $(should-build-cudf) == true ]; then
        print-heading "Cleaning cudf";
        rm -rf "$CUDF_HOME/python/cudf/dist" \
               "$CUDF_HOME/python/cudf/build" \
               "$CUDF_HOME/python/.hypothesis" \
               "$CUDF_HOME/python/cudf/.pytest_cache" \
               "$CUDF_HOME/python/nvstrings/dist" \
               "$CUDF_HOME/python/nvstrings/build" \
               "$CUDF_HOME/python/nvstrings/.pytest_cache";
        find "$CUDF_HOME" -type f -name '*.pyc' -delete;
        find "$CUDF_HOME" -type d -name '__pycache__' -delete;
        find "$CUDF_HOME/python/cudf/cudf" -type f -name '*.so' -delete;
        find "$CUDF_HOME/python/cudf/cudf" -type f -name '*.cpp' -delete;
    else echo "Skipping clean-cudf-python because BUILD_CUDF != YES in your .env file"; fi;
}

export -f clean-cudf-python;

clean-cuml-python() {
    if [ $(should-build-cuml) == true ]; then
        print-heading "Cleaning cuml";
        rm -rf "$CUML_HOME/python/dist" \
               "$CUML_HOME/python/build" \
               "$CUML_HOME/python/.hypothesis" \
               "$CUML_HOME/python/.pytest_cache" \
               "$CUML_HOME/python/external_repositories";
        find "$CUML_HOME" -type f -name '*.pyc' -delete;
        find "$CUML_HOME" -type d -name '__pycache__' -delete;
        find "$CUML_HOME/python/cuml" -type f -name '*.so' -delete;
        find "$CUML_HOME/python/cuml" -type f -name '*.cpp' -delete;
    else echo "Skipping clean-cuml-python because BUILD_CUML != YES in your .env file"; fi;
}

export -f clean-cuml-python;

clean-cugraph-python() {
    if [ $(should-build-cugraph) == true ]; then
        print-heading "Cleaning cugraph";
        rm -rf "$CUGRAPH_HOME/python/dist" \
               "$CUGRAPH_HOME/python/build" \
               "$CUGRAPH_HOME/python/.hypothesis" \
               "$CUGRAPH_HOME/python/.pytest_cache";
        find "$CUGRAPH_HOME" -type f -name '*.pyc' -delete;
        find "$CUGRAPH_HOME" -type d -name '__pycache__' -delete;
        find "$CUGRAPH_HOME/python/cugraph" -type f -name '*.so' -delete;
        find "$CUGRAPH_HOME/python/cugraph" -type f -name '*.cpp' -delete;
    else echo "Skipping clean-cugraph-python because BUILD_CUGRAPH != YES in your .env file"; fi;
}

export -f clean-cugraph-python;

lint-rmm-python() {
    if [ $(should-build-rmm) == true ];
    then print-heading "Linting rmm" && lint-python "$RMM_HOME";
    else echo "Skipping lint-rmm-python because BUILD_RMM != YES in your .env file"; fi;
}

export -f lint-rmm-python;

lint-cudf-python() {
    if [ $(should-build-cudf) == true ];
    then print-heading "Linting cudf" && lint-python "$CUDF_HOME";
    else echo "Skipping lint-cudf-python because BUILD_CUDF != YES in your .env file"; fi;
}

export -f lint-cudf-python;

lint-cuml-python() {
    if [ $(should-build-cuml) == true ];
    then print-heading "Linting cuml" && lint-python "$CUML_HOME";
    else echo "Skipping lint-cuml-python because BUILD_CUML != YES in your .env file"; fi;
}

export -f lint-cuml-python;

lint-cugraph-python() {
    if [ $(should-build-cugraph) == true ];
    then print-heading "Linting cugraph" && lint-python "$CUGRAPH_HOME";
    else echo "Skipping lint-cugraph-python because BUILD_CUGRAPH != YES in your .env file"; fi;
}

export -f lint-cugraph-python;

configure-cpp() {
    update-environment-variables;
    PROJECT_CPP_HOME="$(find-cpp-home)";
    PROJECT_CPP_HOME="${1:-$PROJECT_CPP_HOME}"
    BUILD_DIR="$PROJECT_CPP_HOME/$(cpp-build-dir $PROJECT_CPP_HOME)";
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
        -DPARALLEL_LEVEL=${PARALLEL_LEVEL}
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
    BUILD_TARGETS="${2:-}";
    ENTRY_DIR="$(realpath .)";
    update-environment-variables;
    cd "$1" && cd "$(find-cpp-home)"
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
    cd "$ENTRY_DIR" >/dev/null 2>&1;
}

export -f build-cpp;

build-python() {
    cd "$1";
    CC_="$CC"
    [ "$USE_CCACHE" == "YES" ] && CC_="$(which ccache) $CC";
    export CONDA_PREFIX_="$CONDA_PREFIX"; unset CONDA_PREFIX;
    env CC="$CC_" python setup.py build_ext -j$PARALLEL_LEVEL ${@:2};
    export CONDA_PREFIX="$CONDA_PREFIX_"; unset CONDA_PREFIX_;
    rm -rf ./*.egg-info;
    cd - >/dev/null 2>&1;
}

export -f build-python;

lint-python() {
    cd "$1";
    bash "$COMPOSE_HOME/etc/rapids/lint.sh" || true;
    cd - >/dev/null 2>&1;
}

export -f lint-python;

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

join-list-contents() {
    local IFS='' delim=$1; shift; echo -n "$1"; shift; echo -n "${*/#/$delim}";
}

export -f join-list-contents;

create-cpp-launch-json() {
    mkdir -p "$1/.vscode";
    BUILD_DIR=$(cpp-build-dir $1);
    TESTS_DIR="$1/build/debug/gtests";
    PROJECT_NAME="${1#$RAPIDS_HOME/}";
    TEST_NAMES=$(ls $TESTS_DIR 2>/dev/null || echo "");
    TEST_NAMES=$(echo \"$(join-list-contents '","' $TEST_NAMES)\");
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
            "environment": []
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

print-heading() {
    echo -e "\n\n################\n#\n# $1 \n#\n################\n\n"
}

export -f print-heading;

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
    _BUILD_DIR="cuda-$CUDA_VERSION/${_BUILD_DIR//\//__}"
    echo "build/$_BUILD_DIR/$(cpp-build-type)"
    cd - >/dev/null 2>&1;
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
    set -a && . "$COMPOSE_HOME/.env" && set +a;
    if [ ${CONDA_PREFIX:-""} != "" ]; then
        bash "$CONDA_PREFIX/etc/conda/activate.d/env-vars.sh"
    fi
    unset NVIDIA_VISIBLE_DEVICES
}

export -f update-environment-variables;

# set +Eeo pipefail
