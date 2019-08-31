#!/bin/bash -ex

cd "$RAPIDS_HOME"

D_CMAKE_ARGS="-DCMAKE_CXX11_ABI=ON
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    -DCMAKE_INSTALL_PREFIX=${CONDA_PREFIX}
    -DBUILD_TESTS=${BUILD_TESTS:-OFF}
    -DBUILD_BENCHMARKS=${BUILD_BENCHMARKS:-OFF}
    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release}"

CUDA_VERSION_NO_DOT=$(echo $CUDA_SHORT_VERSION | tr -d '.');

make_compile_commands_json_compatible_with_clangd() {
    cp "$1" "$1.tmp" \
    && sed -r "s/ -x cu / -x cu -x cuda /g" "$1.tmp" > "$1" \
    && rm "$1.tmp"
}

###
# Build librmm
###
cd "$RMM_HOME" && mkdir -p "$RMM_HOME/build" \
 && cd "$RMM_HOME/build" && cmake .. $D_CMAKE_ARGS && make install -j \
 && make_compile_commands_json_compatible_with_clangd "$RMM_HOME/build/compile_commands.json" \
 && cd "$RMM_HOME/python" && python setup.py build_ext -j $(nproc) --inplace && python setup.py install \
 && rm -rf "$RMM_HOME/python/librmm_cffi.egg-info" \
 ;

###
# Build nvstrings
###
cd "$NVSTRINGS_HOME" && mkdir -p "$NVSTRINGS_HOME/cpp/build" \
 && cd "$NVSTRINGS_HOME/cpp/build" && cmake .. $D_CMAKE_ARGS && make install -j \
 && make_compile_commands_json_compatible_with_clangd "$NVSTRINGS_HOME/cpp/build/compile_commands.json" \
 && cd "$NVSTRINGS_HOME/python" && python setup.py install \
 && rm -rf "$NVSTRINGS_HOME/python/nvstrings_cuda$CUDA_VERSION_NO_DOT.egg-info" \
 ;

###
# Build cudf
###
cd "$CUDF_HOME" && mkdir -p "$CUDF_HOME/cpp/build" \
 && cd "$CUDF_HOME/cpp/build" && cmake .. $D_CMAKE_ARGS && make install -j \
 && make_compile_commands_json_compatible_with_clangd "$CUDF_HOME/cpp/build/compile_commands.json" \
 && cd "$CUDF_HOME/python/cudf" && python setup.py build_ext -j $(nproc) --inplace && python setup.py install \
 && cd "$CUDF_HOME/python/dask_cudf" && python setup.py build_ext -j $(nproc) --inplace && python setup.py install \
 && rm -rf "$CUDF_HOME/python/cudf/cudf.egg-info" \
           "$CUDF_HOME/python/dask_cudf/dask_cudf.egg-info" \
 ;

###
# Build cugraph
###
cd "$CUGRAPH_HOME" && mkdir -p "$CUGRAPH_HOME/cpp/build" \
 && cd "$CUGRAPH_HOME/cpp/build" && cmake .. $D_CMAKE_ARGS && make install -j \
 && make_compile_commands_json_compatible_with_clangd "$CUGRAPH_HOME/cpp/build/compile_commands.json" \
 && cd "$CUGRAPH_HOME/python" && python setup.py build_ext -j $(nproc) --inplace && python setup.py install \
 && rm -rf "$CUGRAPH_HOME/python/cugraph.egg-info" \
 ;
