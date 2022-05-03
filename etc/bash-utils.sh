#!/usr/bin/env bash

# set -Eeo pipefail

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
#       the command can be run from any directory.
#
# Note: All commands accept the following optional arguments. These arguments
#       will take precedence over .env configurations. If an argument is
#       omitted, the corresponding .env configuration will be used.
#
# --rmm         Build librmm and rmm
# --cudf        Build libcudf and cudf (implies --rmm)
# --cuml        Build libcuml and cuml (implies --cudf)
# --cugraph     Build libcugraph and cugraph (implies --cudf)
# --cuspatial   Build libcuspatial and cuspatial (implies --cudf)
# -b, --bench   Build C++ benchmarks
# -t, --tests   Build C++ unit tests
# -d, --debug   Build C++ with CMAKE_BUILD_TYPE=Debug
# -r, --release Build C++ with CMAKE_BUILD_TYPE=Release
#
# Examples:
#   build-rmm-cpp --release        Build the librmm C++ library in release mode
#   build-rmm-cpp --debug --tests  Build the librmm C++ library and tests in debug mode
#   clean-rmm-cpp --release        Clean the librmm C++ release mode build artifacts
#                                  for the current git branch, leaving any debug mode
#                                  build artifacts for the current git branch in tact
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
# build-cuspatial-cpp    - (✝) Build the libcuspatial C++ library
#
# build-rmm-python       - (✝) Build the rmm Cython bindings
# build-cudf-python      - (✝) Build the cudf Cython bindings
# build-cuml-python      - (✝) Build the cuml Cython bindings
# build-cugraph-python   - (✝) Build the cugraph Cython bindings
# build-cuspatial-python - (✝) Build the cuspatial Cython bindings
#
# build-cudf-java        - (✝) Build the cudf-java maven artifacts and JNI bindings
#
###
# Commands to clean each project separately:
#
# clean-rmm-cpp          - (✝) Clean the librmm C++ build artifacts for the current git branch
# clean-cudf-cpp         - (✝) Clean the libcudf C++ build artifacts for the current git branch
# clean-cuml-cpp         - (✝) Clean the libcuml C++ build artifacts for the current git branch
# clean-cugraph-cpp      - (✝) Clean the libcugraph C++ build artifacts for the current git branch
# clean-cuspatial-cpp    - (✝) Clean the libcuspatial C++ build artifacts for the current git branch
#
# clean-rmm-python       - (✝) Clean the rmm Cython build assets
# clean-cudf-python      - (✝) Clean the cudf Cython build assets
# clean-cuml-python      - (✝) Clean the cuml Cython build assets
# clean-cugraph-python   - (✝) Clean the cugraph Cython build assets
# clean-cuspatial-python - (✝) Clean the cuspatial Cython build assets
#
# clean-cudf-java        - (✝) Clean the cudf-java maven artifacts and JNI bindings
#
###
# Commands to build documentation for each project separately:
#
# docs-rmm-cpp          - (✝) Build the librmm C++ library documentation
# docs-cudf-cpp         - (✝) Build the libcudf C++ library documentation
# docs-cuml-cpp         - (✝) Build the libcuml C++ library documentation
# docs-cugraph-cpp      - (✝) Build the libcugraph C++ library documentation
# docs-cuspatial-cpp    - (✝) Build the libcuspatial C++ library documentation
#
# docs-rmm-python       - (✝) Build the rmm Python library documentation
# docs-cudf-python      - (✝) Build the cudf library documentation
# docs-cuml-python      - (✝) Build the cuml library documentation
# docs-cugraph-python   - (✝) Build the cugraph library documentation
# docs-cuspatial-python - (✝) Build the cuspatial library documentation
####
# Commands to lint each C++ project separately:
#
# lint-rmm-cpp        - (✝) Lint/fix the librmm C++/CUDA source files with clang-format
# lint-cudf-cpp       - (✝) Lint/fix the libcudf C++/CUDA source files with clang-format
# lint-cuml-cpp       - (✝) Lint/fix the libcuml C++/CUDA source files with clang-format
# lint-cugraph-cpp    - (✝) Lint/fix the libcugraph C++/CUDA source files with clang-format
# lint-cuspatial-cpp  - (✝) Lint/fix the libcuspatial C++/CUDA source files with clang-format
#
###
# Commands to lint each Python project separately:
#
# lint-rmm-python        - (✝) Lint/fix the rmm Cython and Python source files
# lint-cudf-python       - (✝) Lint/fix the cudf Cython and Python source files
# lint-cuml-python       - (✝) Lint/fix the cuml Cython and Python source files
# lint-cugraph-python    - (✝) Lint/fix the cugraph Cython and Python source files
# lint-cuspatial-python  - (✝) Lint/fix the cuspatial Cython and Python source files
#
###
# Commands to run each project's C++ tests:
#
# Note: These commands automatically build (if necessary) before testing.
# Note: Flags are passed to ctest. To see a list of all avaialble flags, run ctest --help
#
# test-rmm-cpp        - (✝) Run librmm C++ tests
# test-cudf-cpp       - (✝) Run libcudf C++ tests
# test-cuml-cpp       - (✝) Run libcuml C++ tests
# test-cugraph-cpp    - (✝) Run libcugraph C++ tests
# test-cuspatial-cpp  - (✝) Run libcuspatial C++ tests
#
# Usage:
# test-rmm-cpp TEST_NAME OTHER_TEST_NAME - Build `TEST_NAME` and `OTHER_TEST_NAME`, then execute.
# test-rmm-cpp TEST_NAME --verbose       - Build and run `TEST_NAME`, passing --verbose to ctest.
#
###
# Commands to run each project's pytests:
#
# Note: These commands automatically change into the correct directory before executing `pytest`.
# Note: Pass --debug to use with the VSCode debugger `debugpy`. All other arguments are forwarded to pytest.
# Note: Arguments that end in '.py' are assumed to be pytest files used to reduce the number of tests
#       collected on startup by pytest. These arguments will be expanded out to their full paths relative
#       to the directory where pytests is run.
#
# test-rmm-python        - (✝) Run rmm pytests
# test-cudf-python       - (✝) Run cudf pytests
# test-cuml-python       - (✝) Run cuml pytests
# test-cugraph-python    - (✝) Run cugraph pytests
# test-cuspatial-python  - (✝) Run cuspatial pytests
#
# Usage:
# test-cudf-python -n <num_cores>                               - Run all pytests in parallel with `pytest-xdist`
# test-cudf-python -v -x -k 'a_test_function_name'              - Run all tests named 'a_test_function_name', be verbose, and exit on first fail
# test-cudf-python -v -x -k 'a_test_function_name' --debug      - Run all tests named 'a_test_function_name', and start debugpy for VSCode debugging
# test-cudf-python -v -x -k 'test_a or test_b' foo/test_file.py - Run all tests named 'test_a' or 'test_b' in file paths matching foo/test_file.py
#
###
# Commands to run the JUnit tests
#
# test-cudf-java        - (✝) Run cudf-java JUnit tests
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
    update-environment-variables $@ >/dev/null;
    $(should-build-cudf) || [ "$BUILD_RMM" == "YES" ] && echo true || echo false;
}

export -f should-build-rmm;

should-build-cudf() {
    update-environment-variables $@ >/dev/null;
    $(should-build-cuml) || $(should-build-cugraph) || $(should-build-cuspatial) || [ "$BUILD_CUDF" == "YES" ] && echo true || echo false;
}

export -f should-build-cudf;

should-build-cuml() {
    update-environment-variables $@ >/dev/null;
    [ "$BUILD_CUML" == "YES" ] && echo true || echo false;
}

export -f should-build-cuml;

should-build-raft() {
    update-environment-variables $@ >/dev/null;
    [ "$BUILD_RAFT" == "YES" ] && echo true || echo false;
}

export -f should-build-raft;

should-build-cugraph() {
    update-environment-variables $@ >/dev/null;
    [ "$BUILD_CUGRAPH" == "YES" ] && echo true || echo false;
}

export -f should-build-cugraph;

should-build-cuspatial() {
    update-environment-variables $@ >/dev/null;
    [ "$BUILD_CUSPATIAL" == "YES" ] && echo true || echo false;
}

export -f should-build-cuspatial;

configure-rapids() {
    (
        set -Eeo pipefail
        print-heading "\
Configuring RAPIDS projects: \
RMM: $(should-build-rmm $@), \
cuDF: $(should-build-cudf $@), \
raft: $(should-build-raft $@), \
cuML: $(should-build-cuml $@), \
cuGraph: $(should-build-cugraph $@), \
cuSpatial: $(should-build-cuspatial $@)";
        if [ $(should-build-rmm) == true ]; then configure-rmm-cpp $@ || exit 1; fi;
        if [ $(should-build-cudf) == true ]; then configure-cudf-cpp $@ || exit 1; fi;
        if [ $(should-build-raft) == true ]; then configure-raft-cpp $@ || exit 1; fi;
        if [ $(should-build-cuml) == true ]; then configure-cuml-cpp $@ || exit 1; fi;
        if [ $(should-build-cugraph) == true ]; then configure-cugraph-cpp $@ || exit 1; fi;
        if [ $(should-build-cuspatial) == true ]; then configure-cuspatial-cpp $@ || exit 1; fi;
    )
}

build-rapids() {
    (
        set -Eeo pipefail
        print-heading "\
Building RAPIDS projects: \
RMM: $(should-build-rmm $@), \
cuDF: $(should-build-cudf $@), \
cuML: $(should-build-cuml $@), \
cuGraph: $(should-build-cugraph $@), \
cuSpatial: $(should-build-cuspatial $@)";
        if [ $(should-build-rmm) == true ]; then build-rmm-cpp $@ || exit 1; fi;
        if [ $(should-build-cudf) == true ]; then build-cudf-cpp $@ || exit 1; fi;
        if [ $(should-build-raft) == true ]; then build-raft-cpp $@ || exit 1; fi;
        if [ $(should-build-cuml) == true ]; then build-cuml-cpp $@ || exit 1; fi;
        if [ $(should-build-cugraph) == true ]; then build-cugraph-cpp $@ || exit 1; fi;
        if [ $(should-build-cuspatial) == true ]; then build-cuspatial-cpp $@ || exit 1; fi;
        if [ $(should-build-rmm) == true ]; then build-rmm-python $@ || exit 1; fi;
        if [ $(should-build-raft) == true ]; then build-raft-python $@ || exit 1; fi;
        if [ $(should-build-cudf) == true ]; then build-cudf-python $@ || exit 1; fi;
        if [ $(should-build-cuml) == true ]; then build-cuml-python $@ || exit 1; fi;
        if [ $(should-build-cugraph) == true ]; then build-cugraph-python $@ || exit 1; fi;
        if [ $(should-build-cuspatial) == true ]; then build-cuspatial-python $@ || exit 1; fi;
    )
}

export -f build-rapids;

clean-rapids() {
    (
        set -Eeo pipefail
        print-heading "\
Cleaning RAPIDS projects: \
RMM: $(should-build-rmm $@), \
cuDF: $(should-build-cudf $@), \
raft: $(should-build-raft $@), \
cuML: $(should-build-cuml $@), \
cuGraph: $(should-build-cugraph $@), \
cuSpatial: $(should-build-cuspatial $@)";

        pids="";

        run-in-background() {
            bash -l <<< "$@" &
            pids="${pids:+$pids }$!"
        }

        run-in-background "if [ \$(should-build-rmm) == true ]; then clean-rmm-cpp $@; fi"
        run-in-background "if [ \$(should-build-cudf) == true ]; then clean-cudf-cpp $@; fi"
        run-in-background "if [ \$(should-build-raft) == true ]; then clean-raft-cpp $@; fi"
        run-in-background "if [ \$(should-build-cuml) == true ]; then clean-cuml-cpp $@; fi"
        run-in-background "if [ \$(should-build-cugraph) == true ]; then clean-cugraph-cpp $@; fi"
        run-in-background "if [ \$(should-build-cuspatial) == true ]; then clean-cuspatial-cpp $@; fi"
        run-in-background "if [ \$(should-build-rmm) == true ]; then clean-rmm-python $@; fi"
        run-in-background "if [ \$(should-build-cudf) == true ]; then clean-cudf-python $@; fi"
        run-in-background "if [ \$(should-build-raft) == true ]; then clean-raft-python $@; fi"
        run-in-background "if [ \$(should-build-cuml) == true ]; then clean-cuml-python $@; fi"
        run-in-background "if [ \$(should-build-cugraph) == true ]; then clean-cugraph-python $@; fi"
        run-in-background "if [ \$(should-build-cuspatial) == true ]; then clean-cuspatial-python $@; fi"

        if [[ "$pids" != "" ]]; then
            # Kill the background procs on ERR/EXIT
            trap "ERRCODE=$? && kill -9 ${pids} >/dev/null 2>&1 || true && exit $ERRCODE" ERR EXIT
            wait ${pids};
        fi
    )
}

export -f clean-rapids;

lint-rapids() {
    (
        set -Eeo pipefail
        print-heading "\
Linting RAPIDS projects: \
RMM: $(should-build-rmm $@), \
cuDF: $(should-build-cudf $@), \
raft: $(should-build-raft $@), \
cuML: $(should-build-cuml $@), \
cuGraph: $(should-build-cugraph $@), \
cuSpatial: $(should-build-cuspatial $@)";
        if [ $(should-build-rmm) == true ]; then lint-rmm-cpp $@ && lint-rmm-python $@ || exit 1; fi
        if [ $(should-build-cudf) == true ]; then lint-cudf-cpp $@ && lint-cudf-python $@ || exit 1; fi
        if [ $(should-build-raft) == true ]; then lint-raft-cpp $@ && lint-raft-python $@ || exit 1; fi
        if [ $(should-build-cuml) ]; then lint-cuml-cpp $@ && lint-cuml-python $@ || exit 1; fi
        if [ $(should-build-cugraph) ]; then lint-cugraph-cpp $@ && lint-cugraph-python $@ || exit 1; fi
        if [ $(should-build-cuspatial) ]; then lint-cuspatial-cpp $@ && lint-cuspatial-python $@ || exit 1; fi
    )
}

export -f lint-rapids;

configure-rmm-cpp() {
    config_args="$@"
    update-environment-variables $@ >/dev/null;
    config_args="-D DISABLE_DEPRECATION_WARNING=${DISABLE_DEPRECATION_WARNINGS:-ON}
                 $config_args"
    config_args=$(echo $(echo "$config_args"));
    print-heading "Configuring librmm";
    configure-cpp "$RMM_HOME" "$config_args";
}

export -f configure-rmm-cpp;

build-rmm-cpp() {
    configure-rmm-cpp "$@";
    print-heading "Building librmm";
    build-cpp "$RMM_HOME" "all";
}

export -f build-rmm-cpp;

configure-cudf-cpp() {
    config_args="$@"
    update-environment-variables $@ >/dev/null;
    config_args="-D rmm_ROOT=${RMM_ROOT}
                 -D DISABLE_DEPRECATION_WARNING=${DISABLE_DEPRECATION_WARNINGS:-ON}
                 $config_args"
    config_args=$(echo $(echo "$config_args"));
    print-heading "Configuring libcudf";
    configure-cpp "$CUDF_HOME/cpp" "$config_args";
}

export -f configure-cudf-cpp;

build-cudf-cpp() {
    configure-cudf-cpp "$@"

    print-heading "Building libcudf";

    build-cpp "$CUDF_HOME/cpp" "all";
}

export -f build-cudf-cpp;

build-cudf-java() {
    config_args="$@"
    update-environment-variables $@ >/dev/null;
    config_args=$(echo $(echo "$config_args"));
    CUDF_JNI_HOME="$CUDF_HOME/java/src/main/native";
    CUDF_CPP_BUILD_DIR="$(find-cpp-build-home $CUDF_HOME)"
    (
        cd "$CUDF_HOME/java";
        mkdir -p "$CUDF_JNI_ROOT_ABS";
        print-heading "Building libcudfjni";

        export CONDA_PREFIX_="$CONDA_PREFIX";
        unset CONDA_PREFIX;

        export CUDF_CPP_BUILD_DIR;

        mvn package \
            ${config_args} \
            -Dmaven.test.skip=true \
            -DCMAKE_CXX11_ABI=ON \
            -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
            -DCUDF_CPP_BUILD_DIR="$CUDF_CPP_BUILD_DIR" \
            -DCUDAToolkit_ROOT="$CUDA_HOME" \
            -DCUDAToolkit_INCLUDE_DIR="$CUDA_HOME/include" \
            -Dnative.build.path="$CUDF_JNI_ROOT"

        export CONDA_PREFIX="$CONDA_PREFIX_";
        unset CONDA_PREFIX_;

        fix-nvcc-clangd-compile-commands "$CUDF_JNI_HOME" "$CUDF_JNI_ROOT_ABS"
    )
}

export -f build-cudf-java;

configure-raft-cpp() {
    config_args="$@"
    update-environment-variables $@ >/dev/null;
    config_args="-D DETECT_CONDA_ENV=OFF
                 -D rmm_ROOT=${RMM_ROOT}
                 -D DISABLE_DEPRECATION_WARNINGS=${DISABLE_DEPRECATION_WARNINGS:-ON}
                 $config_args"
    config_args=$(echo $(echo "$config_args"));
    print-heading "Configuring libraft";
    configure-cpp "$RAFT_HOME/cpp" "$config_args";
}

export -f configure-raft-cpp;

build-raft-cpp() {
    configure-raft-cpp "$@"
    print-heading "Building libraft";
    build-cpp "$RAFT_HOME/cpp" "all";
}

export -f build-raft-cpp;

configure-cuml-cpp() {
    config_args="$@"
    update-environment-variables $@ >/dev/null;
    config_args="-D DETECT_CONDA_ENV=OFF
                 -D rmm_ROOT=${RMM_ROOT}
                 -D raft_ROOT=${RAFT_ROOT}
                 -D BUILD_CUML_MG_TESTS=OFF
                 -D BUILD_CUML_TESTS=${BUILD_TESTS:-OFF}
                 -D BUILD_PRIMS_TESTS=${BUILD_TESTS:-OFF}
                 -D BUILD_CUML_BENCH=${BUILD_BENCHMARKS:-OFF}
                 -D BUILD_CUML_PRIMS_BENCH=${BUILD_BENCHMARKS:-OFF}
                 -D DISABLE_DEPRECATION_WARNINGS=${DISABLE_DEPRECATION_WARNINGS:-ON}
                 $config_args"
    config_args=$(echo $(echo "$config_args"));
    print-heading "Configuring libcuml";
    configure-cpp "$CUML_HOME/cpp" "$config_args";
}

export -f configure-cuml-cpp;

build-cuml-cpp() {
    configure-cuml-cpp "$@"
    print-heading "Building libcuml";
    build-cpp "$CUML_HOME/cpp" "all";
}

export -f build-cuml-cpp;

configure-cugraph-cpp() {
    config_args="$@"
    update-environment-variables $@ >/dev/null;
    config_args="-D rmm_ROOT=${RMM_ROOT}
                 -D raft_ROOT=${RAFT_ROOT}
                 $config_args"
    config_args=$(echo $(echo "$config_args"));
    print-heading "Configuring libcugraph";
    configure-cpp "$CUGRAPH_HOME/cpp" "$config_args";
}

export -f configure-cugraph-cpp;

build-cugraph-cpp() {
    configure-cugraph-cpp "$@";
    print-heading "Building libcugraph";
    build-cpp "$CUGRAPH_HOME/cpp" "all";
}

export -f build-cugraph-cpp;

configure-cuspatial-cpp() {
    config_args="$@"
    update-environment-variables $@ >/dev/null;
    config_args="-D rmm_ROOT=${RMM_ROOT}
                 -D cudf_ROOT=${CUDF_ROOT}
                 -D DISABLE_DEPRECATION_WARNING=${DISABLE_DEPRECATION_WARNINGS:-ON}
                 $config_args"
    config_args=$(echo $(echo "$config_args"));
    print-heading "Configuring libcuspatial";
    configure-cpp "$CUSPATIAL_HOME/cpp" "$config_args";
}

export -f configure-cuspatial-cpp;

build-cuspatial-cpp() {
    configure-cuspatial-cpp "$@"
    print-heading "Building libcuspatial";
    build-cpp "$CUSPATIAL_HOME/cpp" "all";
}

export -f build-cuspatial-cpp;

build-rmm-python() {
    update-environment-variables $@ >/dev/null;
    print-heading "Building rmm";
    build-python "$RMM_HOME/python" --inplace;
}

export -f build-rmm-python;

build-cudf-python() {
    update-environment-variables $@ >/dev/null;
    print-heading "Building cudf";
    build-python "$CUDF_HOME/python/cudf" --inplace;
}

export -f build-cudf-python;

build-raft-python() {
    update-environment-variables $@ >/dev/null;
    print-heading "Building raft";
    build-python "$RAFT_HOME/python" --inplace;
}

export -f build-raft-python;

build-cuml-python() {
    update-environment-variables $@ >/dev/null;
    print-heading "Building cuml";
    build-python "$CUML_HOME/python" --inplace;
}

export -f build-cuml-python;

build-cugraph-python() {
    update-environment-variables $@ >/dev/null;
    print-heading "Building cugraph";
    build-python "$CUGRAPH_HOME/python/cugraph" --inplace;
}

export -f build-cugraph-python;

build-cuspatial-python() {
    update-environment-variables $@ >/dev/null;
    print-heading "Building cuspatial";
    build-python "$CUSPATIAL_HOME/python/cuspatial" --inplace;
}

export -f build-cuspatial-python;

clean-rmm-cpp() {
    update-environment-variables $@ >/dev/null;
    print-heading "Cleaning librmm";
    rm -rf "$RMM_ROOT_ABS";
}

export -f clean-rmm-cpp;

clean-cudf-cpp() {
    update-environment-variables $@ >/dev/null;
    print-heading "Cleaning libcudf";
    rm -rf "$CUDF_ROOT_ABS";
}

export -f clean-cudf-cpp;

clean-cudf-java() {
    update-environment-variables $@ >/dev/null;
    print-heading "Cleaning libcudfjni";
    rm -rf "$CUDF_JNI_ROOT_ABS";
    (
        cd "$CUDF_HOME/java";
        mvn clean -Dnative.build.path="$CUDF_JNI_ROOT"
    )
}

export -f clean-cudf-java;

clean-raft-cpp() {
    update-environment-variables $@ >/dev/null;
    print-heading "Cleaning libraft";
    rm -rf "$RAFT_ROOT_ABS";
}

export -f clean-raft-cpp;

clean-cuml-cpp() {
    update-environment-variables $@ >/dev/null;
    print-heading "Cleaning libcuml";
    rm -rf "$CUML_ROOT_ABS";
}

export -f clean-cuml-cpp;

clean-cugraph-cpp() {
    update-environment-variables $@ >/dev/null;
    print-heading "Cleaning libcugraph";
    rm -rf "$CUGRAPH_ROOT_ABS";
}

export -f clean-cugraph-cpp;

clean-cuspatial-cpp() {
    update-environment-variables $@ >/dev/null;
    print-heading "Cleaning libcuspatial";
    rm -rf "$CUSPATIAL_ROOT_ABS";
}

export -f clean-cuspatial-cpp;

clean-rmm-python() {
    update-environment-variables $@ >/dev/null;
    print-heading "Cleaning rmm";
    rm -rf "$RMM_HOME/python/dist" \
           "$RMM_HOME/python/build";
    find "$RMM_HOME" -type f -name '*.pyc' -delete;
    find "$RMM_HOME" -type d -name '__pycache__' -delete;
    find "$RMM_HOME/python" -type f -name '*.so' -delete;
    find "$RMM_HOME/python" -type f -name '*.cpp' -delete;
}

export -f clean-rmm-python;

clean-cudf-python() {
    update-environment-variables $@ >/dev/null;
    print-heading "Cleaning cudf";
    rm -rf "$CUDF_HOME/.pytest_cache" \
           "$CUDF_HOME/python/cudf/dist" \
           "$CUDF_HOME/python/cudf/build" \
           "$CUDF_HOME/python/.hypothesis" \
           "$CUDF_HOME/python/.pytest_cache" \
           "$CUDF_HOME/python/cudf/.hypothesis" \
           "$CUDF_HOME/python/cudf/.pytest_cache" \
           "$CUDF_HOME/python/dask_cudf/.hypothesis" \
           "$CUDF_HOME/python/dask_cudf/.pytest_cache";
    find "$CUDF_HOME" -type f -name '*.pyc' -delete;
    find "$CUDF_HOME" -type d -name '__pycache__' -delete;
    find "$CUDF_HOME/python/cudf/cudf" -type f -name '*.so' -delete;
    find "$CUDF_HOME/python/cudf/cudf" -type f -name '*.cpp' -delete;
}

export -f clean-cudf-python;

clean-raft-python() {
    update-environment-variables $@ >/dev/null;
    print-heading "Cleaning raft";
    rm -rf "$RAFT_HOME/python/dist" \
           "$RAFT_HOME/python/build" \
           "$RAFT_HOME/python/.hypothesis" \
           "$RAFT_HOME/python/.pytest_cache" \
           "$CUML_HOME/python/cuml/raft" \
           "$CUGRAPH_HOME/python/cugraph/raft";
    find "$RAFT_HOME" -type f -name '*.pyc' -delete;
    find "$RAFT_HOME" -type d -name '__pycache__' -delete;
    find "$RAFT_HOME/python/raft" -type f -name '*.so' -delete;
    find "$RAFT_HOME/python/raft" -type f -name '*.cpp' -delete;
}

export -f clean-raft-python;

clean-cuml-python() {
    update-environment-variables $@ >/dev/null;
    print-heading "Cleaning cuml";
    rm -rf "$CUML_HOME/python/dist" \
           "$CUML_HOME/python/build" \
           "$CUML_HOME/python/cuml/raft" \
           "$CUML_HOME/python/.hypothesis" \
           "$CUML_HOME/python/.pytest_cache" \
           "$CUML_HOME/python/_external_repositories" \
           "$CUML_HOME/python/dask-worker-space";
    find "$CUML_HOME" -type f -name '*.pyc' -delete;
    find "$CUML_HOME" -type d -name '__pycache__' -delete;
    find "$CUML_HOME/python/cuml" -type f -name '*.so' -delete;
    find "$CUML_HOME/python/cuml" -type f -name '*.cpp' -delete;
}

export -f clean-cuml-python;

clean-cugraph-python() {
    update-environment-variables $@ >/dev/null;
    print-heading "Cleaning cugraph";
    rm -rf "$CUGRAPH_HOME/python/cugraph/dist" \
           "$CUGRAPH_HOME/python/cugraph/build" \
           "$CUGRAPH_HOME/python/cugraph/.hypothesis" \
           "$CUGRAPH_HOME/python/cugraph/cugraph/raft" \
           "$CUGRAPH_HOME/python/cugraph/.pytest_cache" \
           "$CUGRAPH_HOME/python/cugraph/_external_repositories" \
           "$CUGRAPH_HOME/python/cugraph/dask-worker-space";
    find "$CUGRAPH_HOME" -type f -name '*.pyc' -delete;
    find "$CUGRAPH_HOME" -type d -name '__pycache__' -delete;
    find "$CUGRAPH_HOME/python/cugraph" -type f -name '*.so' -delete;
    find "$CUGRAPH_HOME/python/cugraph" -type f -name '*.cpp' -delete;
}

export -f clean-cugraph-python;

clean-cuspatial-python() {
    update-environment-variables $@ >/dev/null;
    print-heading "Cleaning cuspatial";
    rm -rf "$CUSPATIAL_HOME/python/.hypothesis" \
           "$CUSPATIAL_HOME/python/.pytest_cache" \
           "$CUSPATIAL_HOME/python/cuspatial/dist" \
           "$CUSPATIAL_HOME/python/cuspatial/build" \
           "$CUSPATIAL_HOME/python/cuspatial/.hypothesis" \
           "$CUSPATIAL_HOME/python/cuspatial/.pytest_cache";
    find "$CUSPATIAL_HOME" -type f -name '*.pyc' -delete;
    find "$CUSPATIAL_HOME" -type d -name '__pycache__' -delete;
    find "$CUSPATIAL_HOME/python/cuspatial/cuspatial" -type f -name '*.so' -delete;
    find "$CUSPATIAL_HOME/python/cuspatial/cuspatial" -type f -name '*.cpp' -delete;
}

export -f clean-cuspatial-python;

docs-rmm-cpp() {
    ARGS="$(update-environment-variables $@)";
    print-heading "Generating docs for libcudf";
    docs-cpp "$RMM_HOME" "rmm_doc" "$RMM_HOME/cpp/doxygen/html" $ARGS;
}

export -f docs-rmm-cpp;

docs-cudf-cpp() {
    ARGS="$(update-environment-variables $@)";
    print-heading "Generating docs for libcudf";
    docs-cpp "$CUDF_HOME" "docs_cudf" "$CUDF_HOME/cpp/doxygen/html" $ARGS;
}

export -f docs-cudf-cpp;

docs-raft-cpp() {
    ARGS="$(update-environment-variables $@)";
    print-heading "Generating docs for libraft";
    docs-cpp "$RAFT_HOME" "doc" "$RAFT_ROOT_ABS/html" $ARGS;
}

export -f docs-raft-cpp;

docs-cuml-cpp() {
    ARGS="$(update-environment-variables $@)";
    print-heading "Generating docs for libcuml";
    docs-cpp "$CUML_HOME" "doc" "$CUML_ROOT_ABS/html" $ARGS;
}

export -f docs-cuml-cpp;

docs-cugraph-cpp() {
    ARGS="$(update-environment-variables $@)";
    print-heading "Generating docs for libcugraph";
    docs-cpp "$CUGRAPH_HOME" "docs_cugraph" "$CUGRAPH_HOME/cpp/doxygen/html" $ARGS;
}

export -f docs-cugraph-cpp;

docs-cuspatial-cpp() {
    ARGS="$(update-environment-variables $@)";
    print-heading "Generating docs for libcuspatial";
    docs-cpp "$CUSPATIAL_HOME" "docs_cuspatial" "doxygen/html" $ARGS;
}

export -f docs-cuspatial-cpp;

docs-rmm-python() {
    ARGS="$(update-environment-variables $@)";
    print-heading "Generating docs for cudf";
    docs-python "$RMM_HOME/docs" "html" $ARGS;
}

export -f docs-rmm-python;

docs-cudf-python() {
    ARGS="$(update-environment-variables $@)";
    print-heading "Generating docs for cudf";
    docs-python "$CUDF_HOME/docs/cudf" "html" $ARGS;
}

export -f docs-cudf-python;

docs-raft-python() {
    ARGS="$(update-environment-variables $@)";
    print-heading "Generating docs for raft";
    docs-python "$RAFT_HOME/docs" "html" $ARGS;
}

export -f docs-raft-python;

docs-cuml-python() {
    ARGS="$(update-environment-variables $@)";
    print-heading "Generating docs for cuml";
    docs-python "$CUML_HOME/docs" "html" $ARGS;
}

export -f docs-cuml-python;

docs-cugraph-python() {
    ARGS="$(update-environment-variables $@)";
    print-heading "Generating docs for cugraph";
    docs-python "$CUGRAPH_HOME/docs" "html" $ARGS;
}

export -f docs-cugraph-python;

docs-cuspatial-python() {
    ARGS="$(update-environment-variables $@)";
    print-heading "Generating docs for cuspatial";
    docs-python "$CUSPATIAL_HOME/docs" "html" $ARGS;
}

export -f docs-cuspatial-python;

lint-rmm-cpp() {
    print-heading "Linting librmm" && lint-cpp "$RMM_HOME";
}

export -f lint-rmm-cpp;

lint-cudf-cpp() {
    print-heading "Linting libcudf" && lint-cpp "$CUDF_HOME";
}

export -f lint-cudf-cpp;

lint-raft-cpp() {
    print-heading "Linting libraft" && lint-cpp "$RAFT_HOME";
}

export -f lint-raft-cpp;

lint-cuml-cpp() {
    print-heading "Linting libcuml" && lint-cpp "$CUML_HOME";
}

export -f lint-cuml-cpp;

lint-cugraph-cpp() {
    print-heading "Linting libcugraph" && lint-cpp "$CUGRAPH_HOME";
}

export -f lint-cugraph-cpp;

lint-cuspatial-cpp() {
    print-heading "Linting libcuspatial" && lint-cpp "$CUSPATIAL_HOME";
}

export -f lint-cuspatial-cpp;

lint-rmm-python() {
    print-heading "Linting rmm" && lint-python "$RMM_HOME" --black --isort --flake8;
}

export -f lint-rmm-python;

lint-cudf-python() {
    print-heading "Linting cudf" && lint-python "$CUDF_HOME" --black --isort --flake8;
}

export -f lint-cudf-python;

lint-raft-python() {
    print-heading "Linting raft" && lint-python "$RAFT_HOME" --flake8;
}

export -f lint-raft-python;

lint-cuml-python() {
    print-heading "Linting cuml" && lint-python "$CUML_HOME" --flake8;
}

export -f lint-cuml-python;

lint-cugraph-python() {
    print-heading "Linting cugraph" && lint-python "$CUGRAPH_HOME" --flake8;
}

export -f lint-cugraph-python;

lint-cuspatial-python() {
    print-heading "Linting cuspatial" && lint-python "$CUSPATIAL_HOME" --black --isort --flake8;
}

export -f lint-cuspatial-python;

test-rmm-cpp() {
    test-cpp "$(find-cpp-build-home $RMM_HOME)" $@;
}

export -f test-rmm-cpp;

test-cudf-cpp() {
    test-cpp "$(find-cpp-build-home $CUDF_HOME)" $@;
}

export -f test-cudf-cpp;

test-cudf-java() {
    TEST_ARGS=$(update-environment-variables $@);
    (
        cd "$CUDF_HOME/java";
        mvn test \
            -Dnative.build.path="$CUDF_JNI_ROOT" \
            ${TEST_ARGS};
    )
}

export -f test-cudf-java;

test-raft-cpp() {
    cd "$(find-cpp-build-home $RAFT_HOME)" && ./test_raft;
}

export -f test-raft-cpp;

test-cuml-cpp() {
    test-cpp "$(find-cpp-build-home $CUML_HOME)" $@;
}

export -f test-cuml-cpp;

test-cugraph-cpp() {
    test-cpp "$(find-cpp-build-home $CUGRAPH_HOME)" $@;
}

export -f test-cugraph-cpp;

test-cuspatial-cpp() {
    test-cpp "$(find-cpp-build-home $CUSPATIAL_HOME)" $@;
}

export -f test-cuspatial-cpp;

test-rmm-python() {
    test-python "$RMM_HOME/python" $@;
}

export -f test-rmm-python;

test-cudf-python() {
    test-python "$CUDF_HOME/python/cudf/cudf/tests" $@;
}

export -f test-cudf-python;

test-dask-cudf-python() {
    test-python "$CUDF_HOME/python/dask_cudf" $@;
}

export -f test-dask-cudf-python;

test-raft-python() {
    test-python "$RAFT_HOME/python" $@;
}

export -f test-raft-python;

test-cuml-python() {
    test-python "$CUML_HOME/python" $@;
}

export -f test-cuml-python;

test-cugraph-python() {
    test-python "$CUGRAPH_HOME/python/cugraph" $@;
}

export -f test-cugraph-python;

test-cuspatial-python() {
    test-python "$CUSPATIAL_HOME/python/cuspatial" $@;
}

export -f test-cuspatial-python;

configure-cpp() {
    (
        set -Eeo pipefail
        D_CMAKE_ARGS=$(update-environment-variables ${@:2});
        D_CMAKE_ARGS=$(echo $(echo "$D_CMAKE_ARGS"));

        SOURCE_DIR="$(find-cpp-home $1)";
        BINARY_DIR="$SOURCE_DIR/$(cpp-build-dir $SOURCE_DIR)";

        # Create or remove ccache compiler symlinks
        set-gcc-version $GCC_VERSION;

        mkdir -p "$BINARY_DIR";

        export CONDA_PREFIX_="$CONDA_PREFIX";
        unset CONDA_PREFIX;

        export CCACHE_BASEDIR="$(realpath -m $BINARY_DIR)"

        cmake -G Ninja \
              -S "$SOURCE_DIR" \
              -B "$BINARY_DIR" \
              -D BUILD_TESTS=$BUILD_TESTS \
              -D BUILD_BENCHMARKS=$BUILD_BENCHMARKS \
              -D CMAKE_PREFIX_PATH="$CONDA_PREFIX_" \
              -D CMAKE_EXPORT_COMPILE_COMMANDS=TRUE \
              -D CMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE \
              -D CMAKE_CUDA_ARCHITECTURES="${CUDAARCHS:-}" \
              -D CMAKE_CUDA_FLAGS="$CMAKE_CUDA_FLAGS" \
              -D CMAKE_CXX_FLAGS="$CMAKE_CXX_FLAGS" \
              ${D_CMAKE_ARGS};

        unset CCACHE_BASEDIR;

        fix-nvcc-clangd-compile-commands "$SOURCE_DIR" "$BINARY_DIR";

        export CONDA_PREFIX="$CONDA_PREFIX_";
        unset CONDA_PREFIX_;
    )
}

export -f configure-cpp;

build-cpp() {
    BUILD_TARGETS="${2:-all}";
    (
        set -Eeo pipefail;
        export CCACHE_BASEDIR="$(find-cpp-build-home $1)";
        export CCACHE_BASEDIR="$(realpath -m $CCACHE_BASEDIR)"
        time cmake --build "$(find-cpp-build-home $1)" -- -j${PARALLEL_LEVEL} $BUILD_TARGETS;
        [ $? == 0 ] && [[ "$(cpp-build-type)" == "release" || -z "$(create-cpp-launch-json $1)" || true ]];
        unset CCACHE_BASEDIR;
    )
}

export -f build-cpp;

build-python() {
    (
        cd "$1";

        # Create or remove ccache compiler symlinks
        set-gcc-version $GCC_VERSION;

        CYTHON_FLAGS="${CYTHON_FLAGS:-}";
        CYTHON_FLAGS="${CYTHON_FLAGS:+$CYTHON_FLAGS }-Wno-reorder";
        CYTHON_FLAGS="${CYTHON_FLAGS:+$CYTHON_FLAGS }-Wno-unknown-pragmas";
        CYTHON_FLAGS="${CYTHON_FLAGS:+$CYTHON_FLAGS }-Wno-unused-variable";

        export CONDA_PREFIX_="$CONDA_PREFIX";
        unset CONDA_PREFIX;

        time env \
             RAFT_PATH="$RAFT_HOME" \
             CFLAGS="${CMAKE_C_FLAGS:+$CMAKE_C_FLAGS }$CYTHON_FLAGS" \
             CXXFLAGS="${CMAKE_CXX_FLAGS:+$CMAKE_CXX_FLAGS }$CYTHON_FLAGS" \
             python setup.py build_ext -j${PARALLEL_LEVEL} ${@:2};

        export CONDA_PREFIX="$CONDA_PREFIX_";
        unset CONDA_PREFIX_;

        rm -rf ./*.egg-info ./.eggs;
    )
}

export -f build-python;

docs-cpp() {
    (
        cd "$(find-cpp-home $1)";
        WATCH=$(echo "$@" | grep " --watch")
        SERVE=$(echo "$@" | grep " --serve")
        BUILD_DIR_PATH="$(find-cpp-build-home $1)"
        pids="";
        if [[ "$WATCH" == "" ]]; then
            bash -lc "echo \"building docs...\" && cmake --build "$BUILD_DIR_PATH" -- $2 2>&1"
        else
            bash -lc "while true; do \
            find doxygen src include -type f \
                \( -iname \*.h \
                -o -iname \*.c \
                -o -iname \*.md \
                -o -iname \*.cu \
                -o -iname \*.cuh \
                -o -iname \*.hpp \
                -o -iname \*.cpp \) \
            | entr -dr sh -c 'echo \"building docs...\" && cmake --build "$BUILD_DIR_PATH" -- $2 2>&1 | tail -n1'; \
            done" &
            pids="${pids:+$pids }$!";
        fi
        if [[ "$SERVE" != "" ]]; then
            PORT="$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1])')";
            bash -lc "python -m http.server -d \"$3\" --bind 0.0.0.0 $PORT" &
            pids="${pids:+$pids }$!";
        fi
        if [[ "$pids" != "" ]]; then
            # Kill the server and doxygen watcher on ERR/EXIT
            trap "ERRCODE=$? && kill -9 ${pids} >/dev/null 2>&1 || true && exit $ERRCODE" ERR EXIT
            wait ${pids};
        fi
    )
}

export -f docs-cpp;

docs-python() {
    (
        cd "$(find-project-home $1)";
        WATCH=$(echo "$@" | grep " --watch")
        SERVE=$(echo "$@" | grep " --serve")
        pids="";
        if [[ "$WATCH" == "" ]]; then
            bash -lc "echo \"building docs...\" && make --no-print-directory $2 -C \"$1\" 2>&1"
            pids="${pids:+$pids }$!";
        else
            bash -lc "while true; do \
            find python \"$1/source\" -type f \
                \( -iname \*.md \
                -o -iname \*.py \
                -o -iname \*.rst \
                -o -iname \*.css \) \
            | entr -dr sh -c 'echo \"building docs...\" && make --no-print-directory $2 -C \"$1\" 2>&1 | tail -n5'; \
            done" &
            pids="${pids:+$pids }$!";
        fi
        if [[ "$SERVE" != "" ]]; then
            PORT="$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1])')";
            bash -lc "python -m http.server -d \"$1/build/html\" --bind 0.0.0.0 $PORT" &
            pids="${pids:+$pids }$!";
        fi
        if [[ "$pids" != "" ]]; then
            # Kill the server and sphinx watcher on ERR/EXIT
            trap "ERRCODE=$? && kill -9 ${pids} >/dev/null 2>&1 || true && exit $ERRCODE" ERR EXIT
            wait ${pids};
        fi
    )
}

export -f docs-python;

lint-cpp() {
    (
        cd "$1";
        CLANG_FORMAT_PY="$(find -type f -name 'run-clang-format.py' | head -n1)"
        if [[ "$CLANG_FORMAT_PY" != "" && -f "$CLANG_FORMAT_PY" ]]; then
            python "$CLANG_FORMAT_PY" -inplace || true;
        fi
    )
}

export -f lint-cpp;

lint-python() {
    (
        cd "$1";
        bash "$COMPOSE_HOME/etc/rapids/lint.sh" ${@:2} || true;
    )
}

export -f lint-python;

set-gcc-version() {
    V="${1:-}";
    if [[ "$V" != "9" && "$V" != "10" && "$V" != "11" ]]; then
        while true; do
            read -p "Please select GCC version 9, 10, or 11: " V </dev/tty
            if [[ $V != "9" && $V != "10" ]]; then
                >&2 echo "Invalid GCC version, please select 9, 10, or 11";
            else
                break;
            fi
        done
    fi
    echo "Using gcc-$V and g++-$V"
    export GCC_VERSION="$V"
    export CXX_VERSION="$V"
    export NVCC="/usr/local/bin/nvcc"
    export CC="/usr/local/bin/gcc-$GCC_VERSION"
    export CXX="/usr/local/bin/g++-$CXX_VERSION"
    echo "rapids" | sudo -S update-alternatives --set gcc /usr/bin/gcc-${GCC_VERSION} >/dev/null 2>&1;
    # Create or remove ccache compiler symlinks
    if [ "$USE_CCACHE" == "YES" ]; then
        echo "rapids" | sudo -S ln -s -f "$(which ccache)" "/usr/local/bin/gcc"                        >/dev/null 2>&1;
        echo "rapids" | sudo -S ln -s -f "$(which ccache)" "/usr/local/bin/g++"                        >/dev/null 2>&1;
        echo "rapids" | sudo -S ln -s -f "$(which ccache)" "/usr/local/bin/nvcc"                       >/dev/null 2>&1;
        echo "rapids" | sudo -S ln -s -f "$(which ccache)" "/usr/local/bin/gcc-$GCC_VERSION"           >/dev/null 2>&1;
        echo "rapids" | sudo -S ln -s -f "$(which ccache)" "/usr/local/bin/g++-$CXX_VERSION"           >/dev/null 2>&1;
    else
        echo "rapids" | sudo -S ln -s -f "/usr/bin/nvcc" "/usr/local/bin/nvcc"                         >/dev/null 2>&1;
        echo "rapids" | sudo -S ln -s -f "/usr/bin/gcc" "/usr/local/bin/gcc"                           >/dev/null 2>&1;
        echo "rapids" | sudo -S ln -s -f "/usr/bin/g++" "/usr/local/bin/g++"                           >/dev/null 2>&1;
        echo "rapids" | sudo -S ln -s -f "/usr/bin/gcc-$GCC_VERSION" "/usr/local/bin/gcc-$GCC_VERSION" >/dev/null 2>&1;
        echo "rapids" | sudo -S ln -s -f "/usr/bin/g++-$CXX_VERSION" "/usr/local/bin/g++-$CXX_VERSION" >/dev/null 2>&1;
    fi
}

export -f set-gcc-version;

test-cpp() {
    (
        update-environment-variables;
        CTESTS="";
        GTESTS="";
        set -x; cd "$1"; { set +x; } 2>/dev/null; shift;
        ###
        # Parse the test names from the input args. Assume all arguments up to
        # a double-dash (`--`) or dash-prefixed (`-*`) argument are test names,
        # and all arguments after are ctest arguments. Strip `--` (if found)
        # from the args list before passing the args to ctest. Example:
        #
        # $ test-cudf-cpp TEST_1,TEST_2 gtests/TEST_3 -- --verbose --parallel
        # $ test-cudf-cpp gtests/TEST_1 gtests/TEST_2 gtests/TEST_3 --verbose --parallel
        ###
        while [[ "$#" -gt 0 ]]; do
            case "$1" in
                --) shift; break;;
                -*) break;;
                *) NAMES=${1:-""};
                for NAME in ${NAMES//,/ }; do
                    NAME="${NAME#gtests/}";
                    CTESTS="${CTESTS:+$CTESTS|}$NAME";
                    GTESTS="${GTESTS:+$GTESTS }gtests/$NAME";
                done;;
            esac; shift;
        done
        for x in "1"; do
            ninja -j${PARALLEL_LEVEL} $GTESTS || break;
            set -x;
            ctest --force-new-ctest-process \
                --output-on-failure \
                ${CTESTS:+-R $CTESTS} $* || break;
            set +x;
        done;
        set +x;
    )
}

test-python() {
    (
        args="";
        paths="";
        debug="false";
        py_regex='.*\.py$';
        arg_regex='^[\-]+';
        number_regex='^[0-9]+$';
        nprocs_regex='^\-n[0-9]*$';
        set -x; cd "$1"; { set +x; } 2>/dev/null; shift;
        while [[ "$#" -gt 0 ]]; do
            # match patterns: [-n, -n auto, -n<nprocs>, -n <nprocs>]
            if [[ $1 =~ $nprocs_regex ]]; then
                args="${args:+$args }$1";
                if [[ "${1#-n}" == "" ]]; then
                    if ! [[ $2 =~ $number_regex ]]; then
                        args="${args:+$args }auto";
                    else
                        args="${args:+$args }$2"; shift;
                    fi;
                fi;
            else
                # match all other pytest arguments/test file names
                case "$1" in
                    --debug) debug="true";;
                    # fuzzy-match test file names and expand to full paths
                    *.py) paths="${paths:+$paths }$(fuzzy-find $1)";;
                    # Match pytest args
                    -*) arr="";
                        args="${args:+$args }$1";
                        # greedy-match args until the next `-<arg>` or .py file
                        while ! [[ "$#" -lt 1 || $2 =~ $arg_regex || $2 =~ $py_regex ]]; do
                            arr="${arr:+$arr }$2"; shift;
                        done;
                        # if only found one sub-argument, append to pytest args list
                        # if multiple, wrap in single-quotes (e.g. -k 'this or that')
                        arr=(${arr});
                        [[ ${#arr[@]} -eq 1 ]] && args="$args ${arr[*]}";
                        [[ ${#arr[@]} -gt 1 ]] && args="$args '${arr[*]}'";
                        ;;
                    *) args="${args:+$args }$1";;
                esac;
            fi; shift;
        done;
        if [[ $debug != true ]]; then
            eval "set -x; pytest $args $paths";
        else
            eval "set -x; python -m debugpy --listen 0.0.0.0:5678 --wait-for-client -m pytest $args $paths";
        fi
    )
}

export -f test-python;

fix-nvcc-clangd-compile-commands() {
    # fix-nvcc-clangd-compile-commands "$PROJECT_CPP_HOME" "$PROJECT_CPP_BUILD_DIR";
    CPP_DIR=$(find-cpp-home "${1:-.}");
    BUILD_DIR="$(cpp-build-dir $CPP_DIR)";
    BUILD_DIR="${2:-$CPP_DIR/$BUILD_DIR}";

    (
        set -Eeo pipefail;
        ###
        # Make a few modifications to the compile_commands.json file
        # produced by CMake. This file is used by clangd to provide fast
        # and smart intellisense, but `clang-11` doesn't yet support all
        # the nvcc compilation options. This block translates or removes
        # unsupported options, so `clangd` has an easier time producing
        # usable intellisense results.
        ###
        CC_JSON="$BUILD_DIR/compile_commands.json";
        CC_JSON_LINK="$CPP_DIR/compile_commands.json";
        CC_JSON_CLANGD="$BUILD_DIR/compile_commands.clangd.json";

        if [ ! -f "$CC_JSON" ] && [ -f "$CC_JSON.orig" ]; then
            cp "$CC_JSON.orig" "$CC_JSON";
        fi

        if [ ! -f "$CC_JSON" ]; then
            echo "File not found: $CC_JSON"
            exit 1;
        fi

        cat "$CC_JSON"                                              \
        `# Rewrite '-isystem=' to '-isystem '`                      \
        | sed -r "s/-isystem=/-isystem /g"                          \
        `# Rewrite /usr/local/bin/gcc to /usr/bin/gcc`              \
        | sed -r "s@/usr/local/bin/gcc@/usr/bin/gcc@g"              \
        `# Rewrite /usr/local/bin/g++ to /usr/bin/g++`              \
        | sed -r "s@/usr/local/bin/g\+\+@/usr/bin/g\+\+@g"          \
        `# Rewrite /usr/local/bin/nvcc to /usr/local/cuda/bin/nvcc` \
        | sed -r "s@/usr/local/bin/nvcc@$CUDA_HOME/bin/nvcc@g"      \
        `# Rewrite /usr/local/cuda to /usr/local/cuda-X.Y`          \
        | sed -r "s@$CUDA_HOME@$(realpath -m $CUDA_HOME)@g"         \
        > "$CC_JSON_CLANGD"                                         ;

        # symlink compile_commands.clangd.json to the project root so clangd can find it
        make-symlink "$CC_JSON_CLANGD" "$CC_JSON_LINK";

        mv "$CC_JSON" "$CC_JSON.orig";

        cat << EOF > "$CPP_DIR/.vscode/c_cpp_properties.json"
{
    "version": 4,
    "configurations": [
        {
            "name": "$(basename `find-project-home $CPP_DIR`)",
            "compileCommands": "$CC_JSON_LINK"
        }
    ]
}
EOF

        rm -rf "$CPP_DIR/.clangd";
        cat << EOF > "$CPP_DIR/.clangd"
# Apply this config conditionally to all C files
If:
  PathMatch: .*\.(c|h)$
CompileFlags:
  Compiler: /usr/bin/gcc-$GCC_VERSION

---

# Apply this config conditionally to all C++ headers
If:
  PathMatch: .*\.(c|h)pp$
CompileFlags:
  Compiler: /usr/bin/g++-$CXX_VERSION

---

# Apply this config conditionally to all CUDA headers
If:
  PathMatch: .*\.cuh?$
CompileFlags:
  Compiler: $CUDA_HOME/bin/nvcc

---

# Tweak the clangd parse settings for all files
CompileFlags:
  Add:
    # report all errors
    - "-ferror-limit=0"
  Remove:
    # strip CUDA fatbin args
    - "-Xfatbin*"
    # strip CUDA arch flags
    - "-gencode*"
    - "--generate-code*"
    # strip CUDA flags unknown to clang
    - "--expt-extended-lambda"
    - "--expt-relaxed-constexpr"
    - "-forward-unknown-to-host-compiler"
    - "-Werror=cross-execution-space-call"
Hover:
  ShowAKA: No
InlayHints:
  Enabled: No
Diagnostics:
  Suppress:
    - "variadic_device_fn"
    - "attributes_not_allowed"
    - "-Wdeprecated-declarations"
EOF
    )
}

export -f fix-nvcc-clangd-compile-commands;

fuzzy-find() {
    (
        for p in ${@}; do
            path="${p#./}"; # remove leading ./ (if exists)
            ext="${p##*.}"; # extract extension (if exists)
            if [[ $ext == $p ]];
                then echo $(find .                -print0 | grep -FzZ $path | tr '\0' '\n');
                else echo $(find . -name "*.$ext" -print0 | grep -FzZ $path | tr '\0' '\n');
            fi;
        done
    )
}

export -f fuzzy-find;

join-list-contents() {
    local IFS='' delim=$1; shift; echo -n "$1"; shift; echo -n "${*/#/$delim}";
}

export -f join-list-contents;

create-cpp-launch-json() {
    (
        cd "$(find-cpp-home ${1:-$PWD})"
        mkdir -p "$PWD/.vscode";
        BUILD_DIR=$(cpp-build-dir $PWD);
        TESTS_DIR="$PWD/build/debug/gtests";
        PROJECT_NAME="${PWD#$RAPIDS_HOME/}";
        TEST_NAMES=$(ls $TESTS_DIR 2>/dev/null || echo "");
        TEST_NAMES=$(echo \"$(join-list-contents '","' $TEST_NAMES)\");
        cat << EOF > "$PWD/.vscode/launch.json"
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "$PROJECT_NAME cuda-gdb",
            "type": "cuda-gdb",
            "request": "launch",
            "gdb": "$(realpath -m $CUDA_HOME)/bin/cuda-gdb",
            "program": "$TESTS_DIR/\${input:TEST_NAME}",
            "cwd": "$TESTS_DIR/"
        },
        {
            "name": "$PROJECT_NAME cppdbg",
            "type": "cppdbg",
            "request": "launch",
            "program": "$TESTS_DIR/\${input:TEST_NAME}",
            "cwd": "$TESTS_DIR/"
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
    )
}

export -f create-cpp-launch-json;

print-heading() {
    (
        msg=""
        for ((i=1; i<=${#1}+4; i++)); do msg="$msg#"; done
        msg="$msg\n# $1 #\n"
        for ((i=1; i<=${#1}+4; i++)); do msg="$msg#"; done
        echo -e "$msg"
    )
}

export -f print-heading;

find-project-home() {
    PROJECT_HOMES="\
    $RMM_HOME
    $CUDF_HOME
    $CUML_HOME
    $RAFT_HOME
    $CUGRAPH_HOME
    $CUSPATIAL_HOME
    $NOTEBOOKS_CONTRIB_HOME";
    CURDIR="$(realpath ${1:-$PWD})"
    for PROJECT_HOME in $PROJECT_HOMES; do
        if [ -n "$(echo "$CURDIR" | grep "$PROJECT_HOME" - || echo "")" ]; then
            echo "$PROJECT_HOME"; break;
        fi;
    done
}

export -f find-project-home;

find-cpp-home() {
    PROJECT_HOME="$(find-project-home $@)";
    if [ "$PROJECT_HOME" != "$RMM_HOME" ]; then
        PROJECT_HOME="$PROJECT_HOME/cpp"
    fi;
    echo "$PROJECT_HOME";
}

export -f find-cpp-home;

find-cpp-build-home() {
    echo "$(find-cpp-home $@)/build/$(cpp-build-type)";
}

export -f find-cpp-build-home;

cpp-build-type() {
    echo "${CMAKE_BUILD_TYPE:-Release}" | tr '[:upper:]' '[:lower:]'
}

export -f cpp-build-type;

cpp-build-dir() {
    (
        cd "$1"
        _BUILD_DIR="$(git branch --show-current)";
        _BUILD_DIR="cuda-$CUDA_VERSION/${_BUILD_DIR//\//__}"
        echo "build/$_BUILD_DIR/$(cpp-build-type)";
    )
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
    GCC_VER="$GCC_VERSION"
    set -a && . "$COMPOSE_HOME/.env" && set +a;
    unset NVIDIA_VISIBLE_DEVICES;
    export GCC_VERSION="$GCC_VER";
    args=
    tests=
    bench=
    btype=
    build_rmm=
    build_cudf=
    build_cuml=
    build_raft=
    build_cugraph=
    build_cuspatial=
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -b|--bench) bench="${bench:-ON}";;
            -t|--tests) tests="${tests:-ON}";;
            -d|--debug) btype="${btype:-Debug}";;
            -r|--release) btype="${btype:-Release}";;
            --rmm) build_rmm="${build_rmm:-YES}";;
            --cudf) build_cudf="${build_cudf:-YES}";;
            --raft) build_raft="${build_raft:-YES}";;
            --cuml) build_cuml="${build_cuml:-YES}";;
            --cugraph) build_cugraph="${build_cugraph:-YES}";;
            --cuspatial) build_cuspatial="${build_cuspatial:-YES}";;
            *) args="${args:+$args }$1";;
        esac; shift;
    done
    export BUILD_RMM="${build_rmm:-$BUILD_RMM}"
    export BUILD_CUDF="${build_cudf:-$BUILD_CUDF}"
    export BUILD_CUML="${build_cuml:-$BUILD_CUML}"
    export BUILD_RAFT="${build_raft:-$BUILD_RAFT}"
    export BUILD_CUGRAPH="${build_cugraph:-$BUILD_CUGRAPH}"
    export BUILD_CUSPATIAL="${build_cuspatial:-$BUILD_CUSPATIAL}"
    export BUILD_TESTS="${tests:-$BUILD_TESTS}";
    export BUILD_BENCHMARKS="${bench:-$BUILD_BENCHMARKS}";
    export CMAKE_BUILD_TYPE="${btype:-$CMAKE_BUILD_TYPE}";

    export RMM_ROOT_ABS="$RMM_HOME/$(cpp-build-dir $RMM_HOME)"
    export CUDF_ROOT_ABS="$CUDF_HOME/cpp/$(cpp-build-dir $CUDF_HOME)"
    export RAFT_ROOT_ABS="$RAFT_HOME/cpp/$(cpp-build-dir $RAFT_HOME)"
    export CUML_ROOT_ABS="$CUML_HOME/cpp/$(cpp-build-dir $CUML_HOME)"
    export CUGRAPH_ROOT_ABS="$CUGRAPH_HOME/cpp/$(cpp-build-dir $CUGRAPH_HOME)"
    export CUSPATIAL_ROOT_ABS="$CUSPATIAL_HOME/cpp/$(cpp-build-dir $CUSPATIAL_HOME)"

    export CUDAARCHS="${CUDAARCHS:-${CMAKE_CUDA_ARCHITECTURES:-}}"
    export CMAKE_C_FLAGS="${CFLAGS:+$CFLAGS }-fdiagnostics-color=always"
    export CMAKE_CXX_FLAGS="${CXXFLAGS:+$CXXFLAGS }-fdiagnostics-color=always"
    export CMAKE_CUDA_FLAGS="${CUDAFLAGS:+$CUDAFLAGS }-Xcompiler=-fdiagnostics-color=always"

    if [[ "${DISABLE_DEPRECATION_WARNINGS:-ON}" == "ON" ]]; then
        export DISABLE_DEPRECATION_WARNINGS=ON
        export CMAKE_C_FLAGS="${CMAKE_C_FLAGS:+$CMAKE_C_FLAGS }-Wno-deprecated-declarations"
        export CMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS:+$CMAKE_CXX_FLAGS }-Wno-deprecated-declarations"
        export CMAKE_CUDA_FLAGS="${CMAKE_CUDA_FLAGS:+$CMAKE_CUDA_FLAGS }-Xcompiler=-Wno-deprecated-declarations"
    else
        export DISABLE_DEPRECATION_WARNINGS=OFF
    fi;

    REACTIVATE_ENV="";

    if [ -f /tmp/.last_env ]; then
        REACTIVATE_ENV="$(diff -qwB /tmp/.last_env <(env) || true)"
    fi

    if [ -n "${REACTIVATE_ENV// }" ] && [ ${CONDA_PREFIX:-""} != "" ]; then
        source "$CONDA_PREFIX/etc/conda/activate.d/env-vars.sh"
    fi
    # return the rest of the unparsed args
    echo "$args";
}

export -f update-environment-variables;

# set +Eeo pipefail
