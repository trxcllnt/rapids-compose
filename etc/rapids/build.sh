#!/usr/bin/env bash

set -e
set -x

cd "$RAPIDS_HOME"

D_CMAKE_ARGS="\
    -GNinja
    -DCONDA_BUILD=0
    -DCMAKE_CXX11_ABI=ON
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    -DBUILD_TESTS=${BUILD_TESTS:-OFF}
    -DCMAKE_INSTALL_PREFIX=${CONDA_PREFIX}
    -DCMAKE_SYSTEM_PREFIX_PATH=${CONDA_PREFIX}
    -DBUILD_BENCHMARKS=${BUILD_BENCHMARKS:-OFF}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release}"

_make_compile_commands_json_compatible_with_clangd() {
    cp "$1" "$1.tmp" \
    && sed -r "s/ -x cu / -x cu -x cuda /g" "$1.tmp" > "$1" \
    && rm "$1.tmp"
}

_build_cpp() {
    cd "$1" && mkdir -p "$1/build" \
 && cd "$1/build" && PARALLEL_LEVEL=$(nproc) cmake $D_CMAKE_ARGS .. \
 && _make_compile_commands_json_compatible_with_clangd "$1/build/compile_commands.json" \
 && ninja install
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

# This gets around the cudf CMakeList.txt's new "Conda environment detected"
# feature. This feature adds CONDA_PREFIX to the INCLUDE_DIRS and LINK_DIRS
# lists, and causes g++ to relink all the shared objects when the conda env
# changes. This leads to the notebooks container recompiling all the C++
# artifacts when nothing material has changed since they were built by the
# rapids container.
unset CONDA_PREFIX

echo -e "\n\n\n\n# Building rapids projects" \
 && _print_heading "librmm"     && _build_cpp "$RMM_HOME" \
 && _print_heading "libcudf"    && _build_cpp "$CUDF_HOME/cpp" \
 && _print_heading "libcugraph" && _build_cpp "$CUGRAPH_HOME/cpp" \
 && _print_heading "rmm"        && _build_python "$RMM_HOME/python" --inplace \
 && _print_heading "nvstrings"  && _build_python "$CUDF_HOME/python/nvstrings" \
 && _print_heading "cudf"       && _build_python "$CUDF_HOME/python/cudf" --inplace \
 && _print_heading "dask_cudf"  && _build_python "$CUDF_HOME/python/dask_cudf" --inplace \
 && _print_heading "cugraph"    && _build_python "$CUGRAPH_HOME/python" --inplace \
 ;
