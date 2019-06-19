ARG CUDA_VERSION=9.2
ARG RAPIDS_VERSION=latest
ARG RAPIDS_NAMESPACE=anon
ARG CUDA_SHORT_VERSION=${CUDA_VERSION}

FROM rapidsai/${RAPIDS_NAMESPACE}/rmm:${RAPIDS_VERSION} AS rmm_base
FROM rapidsai/${RAPIDS_NAMESPACE}/custrings:${RAPIDS_VERSION} AS custrings_base
FROM rapidsai/${RAPIDS_NAMESPACE}/cuda:${RAPIDS_VERSION}

COPY --from=rmm_base ${RMM_ROOT}/lib/librmm.so ${RMM_ROOT}/lib/librmm.so
COPY --from=rmm_base ${RMM_ROOT}/include/rmm ${RMM_ROOT}/include/rmm

COPY --from=custrings_base ${CUSTRINGS_ROOT}/lib/libNVText.so ${CUSTRINGS_ROOT}/lib/libNVText.so
COPY --from=custrings_base ${CUSTRINGS_ROOT}/lib/libNVStrings.so ${CUSTRINGS_ROOT}/lib/libNVStrings.so
COPY --from=custrings_base ${CUSTRINGS_ROOT}/lib/libNVCategory.so ${CUSTRINGS_ROOT}/lib/libNVCategory.so
COPY --from=custrings_base ${CUSTRINGS_ROOT}/include/nvstrings ${CUSTRINGS_ROOT}/include/nvstrings

###
# Build libcudf and cuDF
###
COPY cudf/cpp ${CUDF_HOME}/cpp
COPY cudf/thirdparty ${CUDF_HOME}/thirdparty
RUN mkdir -p ${CUDF_HOME}/cpp/build && cd ${CUDF_HOME}/cpp/build \
 && cmake .. -DCMAKE_INSTALL_PREFIX=${CUDF_ROOT} -DBUILD_TESTS=${BUILD_TESTS:-OFF} \
 && make install -j

COPY cudf/python ${CUDF_HOME}/python
RUN cd ${CUDF_HOME}/python && python setup.py build_ext --inplace





# ARG CUDA_SHORT_VERSION
# ONBUILD ARG CUDA_SHORT_VERSION
# ONBUILD ARG NUMBA_VERSION
# ONBUILD ENV NUMBA_VERSION=$NUMBA_VERSION
# ONBUILD ARG NUMPY_VERSION
# ONBUILD ENV NUMPY_VERSION=$NUMPY_VERSION
# ONBUILD ARG PANDAS_VERSION
# ONBUILD ENV PANDAS_VERSION=$PANDAS_VERSION
# ONBUILD ARG PYARROW_VERSION
# ONBUILD ENV PYARROW_VERSION=$PYARROW_VERSION
# ONBUILD ARG CYTHON_VERSION
# ONBUILD ENV CYTHON_VERSION=$CYTHON_VERSION
# ONBUILD ARG CMAKE_VERSION
# ONBUILD ENV CMAKE_VERSION=$CMAKE_VERSION

# # Add the cudf conda and docker folders
# ONBUILD COPY cudf/conda /opt/rapids/cudf/conda
# ONBUILD COPY cudf/docker /opt/rapids/cudf/docker

# # Run a bash script to modify the environment file based on versions set in build args
# ONBUILD RUN /opt/rapids/cudf/docker/package_versions.sh \
#     /opt/rapids/cudf/conda/environments/cudf_dev_cuda${CUDA_SHORT_VERSION}.yml \
#  && sed -i 's/cudf_dev/base/g' /opt/rapids/cudf/conda/environments/cudf_dev_cuda${CUDA_SHORT_VERSION}.yml

# ONBUILD ARG BUILD_TESTS=OFF

# # Install cudf dependencies into the conda base environment to speed up subsequent builds
# ONBUILD RUN conda env update -n base -f /opt/rapids/cudf/conda/environments/cudf_dev_cuda${CUDA_SHORT_VERSION}.yml

# # Build and install libcudf
# ONBUILD COPY cudf/cpp /opt/rapids/cudf/cpp
# ONBUILD COPY cudf/thirdparty /opt/rapids/cudf/thirdparty
# ONBUILD RUN mkdir -p /opt/rapids/cudf/cpp/build && cd /opt/rapids/cudf/cpp/build \
#  && cmake .. -DCMAKE_INSTALL_PREFIX=${CONDA_PREFIX} -DBUILD_TESTS=${BUILD_TESTS:-OFF} \
#  && make install -j

# # Build and install cuDF
# ONBUILD COPY cudf/python /opt/rapids/cudf/python
# ONBUILD RUN cd /opt/rapids/cudf/python && python setup.py build_ext --inplace

# ONBUILD COPY cudf/.git /opt/rapids/cudf/.git
# ONBUILD RUN cd /opt/rapids/cudf/python && python setup.py install
