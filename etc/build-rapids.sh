#!/bin/bash -ex

cd $RAPIDS_HOME

###
# Build librmm
###
mkdir -p "$RMM_ROOT/build" && cd "$RMM_ROOT/build" \
 && cmake .. -DBUILD_TESTS=${BUILD_TESTS:-OFF} \
             -DCMAKE_INSTALL_PREFIX="$RMM_ROOT/build" \
             -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release} \
 && make install -j \
 && ln -s "$RMM_INCLUDE/rmm" /usr/local/include/rmm \
 && ln -s "$RMM_ROOT/build/lib/librmm.so" /usr/local/lib/librmm.so \
 && make rmm_python_cffi

###
# Build nvstrings
###
mkdir -p "$NVSTRINGS_ROOT/build" && cd "$NVSTRINGS_ROOT/build" \
 && cmake .. -DBUILD_TESTS=${BUILD_TESTS:-OFF} \
             -DCMAKE_INSTALL_PREFIX="$NVSTRINGS_ROOT/build" \
             -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release} \
 && make install -j \
 && ln -s "$NVSTRINGS_INCLUDE" /usr/local/include/nvstrings \
 && ln -s "$NVSTRINGS_ROOT/build/lib/libNVText.so" /usr/local/lib/libNVText.so \
 && ln -s "$NVSTRINGS_ROOT/build/lib/libNVStrings.so" /usr/local/lib/libNVStrings.so \
 && ln -s "$NVSTRINGS_ROOT/build/lib/libNVCategory.so" /usr/local/lib/libNVCategory.so \
 && cd "$NVSTRINGS_HOME/python" && python setup.py install

###
# Build libcudf and cuDF
###
mkdir -p "$CUDF_ROOT/build" && cd "$CUDF_ROOT/build" \
 && cmake .. -DBUILD_TESTS=${BUILD_TESTS:-OFF} \
             -DCMAKE_INSTALL_PREFIX="$CUDF_ROOT/build" \
             -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release} \
 && make install -j \
 && ln -s "$CUDF_INCLUDE/cudf" /usr/local/include/cudf \
 && ln -s "$CUDF_ROOT/build/lib/libcudf.so" /usr/local/lib/libcudf.so \
 && cd "$CUDF_HOME/python/cudf" && python setup.py build_ext --inplace \
 && cd "$CUDF_HOME/python/dask_cudf" && python setup.py build_ext --inplace

# Build libcugraph and cuGraph
mkdir -p "$CUGRAPH_ROOT/build" && cd "$CUGRAPH_ROOT/build" \
 && cmake .. -DBUILD_TESTS=${BUILD_TESTS:-OFF} \
             -DCMAKE_INSTALL_PREFIX="$CUGRAPH_ROOT/build" \
             -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release} \
 && make install -j \
 && ln -s "$CUGRAPH_INCLUDE" /usr/local/include/cugraph \
 && ln -s "$CUGRAPH_ROOT/build/lib/libcugraph.so" /usr/local/lib/libcugraph.so \
 && cd "$CUGRAPH_HOME/python" && python setup.py build_ext --inplace

chown -R ${_UID}:${_GID} \
    "$RMM_HOME" \
    "$CUDF_HOME" \
    "$CUGRAPH_HOME" \
    "$NVSTRINGS_HOME"
