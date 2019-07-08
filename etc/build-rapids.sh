#!/bin/bash -ex

cd /opt/rapids

###
# Build librmm
###
mkdir -p ${RMM_ROOT} && cd ${RMM_ROOT} \
 && cmake .. -DBUILD_TESTS=${BUILD_TESTS:-OFF} \
             -DCMAKE_INSTALL_PREFIX="$RMM_ROOT" \
             -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release} \
 && make install -j

ln -s "$RMM_INCLUDE/rmm" /usr/local/include/rmm

make rmm_python_cffi

###
# Build custrings
###
mkdir -p "$CUSTRINGS_ROOT" && cd "$CUSTRINGS_ROOT" \
 && cmake .. -DBUILD_TESTS=${BUILD_TESTS:-OFF} \
             -DCMAKE_INSTALL_PREFIX="$CUSTRINGS_ROOT" \
             -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release} \
 && make install -j

ln -s "$CUSTRINGS_INCLUDE/nvstrings" /usr/local/include/nvstrings
ln -s "$CUSTRINGS_ROOT/lib/libNVText.so" /usr/local/lib/libNVText.so
ln -s "$CUSTRINGS_ROOT/lib/libNVStrings.so" /usr/local/lib/libNVStrings.so
ln -s "$CUSTRINGS_ROOT/lib/libNVCategory.so" /usr/local/lib/libNVCategory.so

cd "$CUSTRINGS_HOME/python" && python setup.py install

###
# Build libcudf and cuDF
###
mkdir -p "$CUDF_ROOT" && cd "$CUDF_ROOT" \
 && cmake .. -DBUILD_TESTS=${BUILD_TESTS:-OFF} \
             -DCMAKE_INSTALL_PREFIX="$CUDF_ROOT" \
             -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release} \
 && make install -j

ln -s "$CUDF_INCLUDE/cudf" /usr/local/include/cudf
ln -s "$CUDF_ROOT/lib/libcudf.so" /usr/local/lib/libcudf.so

cd "$CUDF_HOME/python/cudf" && python setup.py build_ext --inplace
cd "$CUDF_HOME/python/dask_cudf" && python setup.py build_ext --inplace

# Build libcugraph and cuGraph
mkdir -p "$CUGRAPH_ROOT" && cd "$CUGRAPH_ROOT" \
 && cmake .. -DBUILD_TESTS=${BUILD_TESTS:-OFF} \
             -DCMAKE_INSTALL_PREFIX="$CUGRAPH_ROOT" \
             -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-Release} \
 && make install -j

ln -s "$CUGRAPH_INCLUDE/cugraph" /usr/local/include/cugraph
ln -s "$CUGRAPH_ROOT/lib/libcugraph.so" /usr/local/lib/libcugraph.so

cd "$CUGRAPH_HOME/python" && python setup.py build_ext --inplace

chown -R ${_UID}:${_GID} \
    "$RMM_HOME" \
    "$CUDF_HOME" \
    "$CUGRAPH_HOME" \
    "$CUSTRINGS_HOME"
