ARG CUDA_VERSION=9.2
ARG RAPIDS_VERSION=latest
ARG RAPIDS_NAMESPACE=anon
ARG CUDA_SHORT_VERSION=${CUDA_VERSION}

FROM rapidsai/${RAPIDS_NAMESPACE}/rmm:${RAPIDS_VERSION} AS rmm_base
FROM rapidsai/${RAPIDS_NAMESPACE}/custrings:${RAPIDS_VERSION} AS custrings_base
FROM rapidsai/${RAPIDS_NAMESPACE}/cudf:${RAPIDS_VERSION} AS cudf_base
FROM rapidsai/${RAPIDS_NAMESPACE}/cuda:${RAPIDS_VERSION}

COPY --from=rmm_base ${RMM_ROOT}/lib/librmm.so ${RMM_ROOT}/lib/librmm.so
COPY --from=rmm_base ${RMM_ROOT}/include/rmm ${RMM_ROOT}/include/rmm

COPY --from=custrings_base ${CUSTRINGS_ROOT}/lib/libNVText.so ${CUSTRINGS_ROOT}/lib/libNVText.so
COPY --from=custrings_base ${CUSTRINGS_ROOT}/lib/libNVStrings.so ${CUSTRINGS_ROOT}/lib/libNVStrings.so
COPY --from=custrings_base ${CUSTRINGS_ROOT}/lib/libNVCategory.so ${CUSTRINGS_ROOT}/lib/libNVCategory.so
COPY --from=custrings_base ${CUSTRINGS_ROOT}/include/nvstrings ${CUSTRINGS_ROOT}/include/nvstrings

COPY --from=cudf_base ${CUSTRINGS_ROOT}/lib/libcudf.so ${CUSTRINGS_ROOT}/lib/libcudf.so
COPY --from=cudf_base ${CUDF_ROOT}/include/cudf ${CUDF_ROOT}/include/cudf

# Build libcugraph and cuGraph
COPY cugraph/cpp ${CUGRAPH_HOME}/cpp
COPY cugraph/thirdparty ${CUGRAPH_HOME}/thirdparty
RUN mkdir -p ${CUGRAPH_HOME}/cpp/build && cd ${CUGRAPH_HOME}/cpp/build \
 && cmake .. -DCMAKE_INSTALL_PREFIX=${CUGRAPH_ROOT} -DBUILD_TESTS=${BUILD_TESTS:-OFF} \
 && make install -j

COPY cugraph/python ${CUGRAPH_HOME}/python
RUN cd ${CUGRAPH_HOME}/python && python setup.py build_ext --inplace





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

# # Add the cugraph conda and docker folders
# ONBUILD COPY cugraph/conda /opt/rapids/cugraph/conda
# ONBUILD COPY cudf/docker /opt/rapids/cugraph/docker

# # Run a bash script to modify the environment file based on versions set in build args
# # Rename the conda env files to match the cudf build
# ONBUILD RUN mv /opt/rapids/cugraph/conda/environments/cugraph_dev.yml \
#        /opt/rapids/cugraph/conda/environments/cugraph_dev_cuda9.2.yml \
#  && mv /opt/rapids/cugraph/conda/environments/cugraph_dev_cuda10.yml \
#        /opt/rapids/cugraph/conda/environments/cugraph_dev_cuda10.0.yml \
#  && /opt/rapids/cugraph/docker/package_versions.sh \
#     /opt/rapids/cugraph/conda/environments/cugraph_dev_cuda${CUDA_SHORT_VERSION}.yml \
#  && sed -i 's/cugraph_dev/base/g' /opt/rapids/cugraph/conda/environments/cugraph_dev_cuda${CUDA_SHORT_VERSION}.yml

# ONBUILD ARG BUILD_TESTS=OFF
# ONBUILD ENV CUGRAPH_HOME=/opt/rapids/cugraph

# # Install cugraph dependencies into the conda base environment to speed up subsequent builds
# ONBUILD RUN conda env update -n base -f /opt/rapids/cugraph/conda/environments/cugraph_dev_cuda${CUDA_SHORT_VERSION}.yml

# # Build and install libcugraph
# ONBUILD COPY cugraph/cpp /opt/rapids/cugraph/cpp
# ONBUILD COPY cugraph/thirdparty /opt/rapids/cugraph/thirdparty
# ONBUILD RUN mkdir -p /opt/rapids/cugraph/cpp/build && cd /opt/rapids/cugraph/cpp/build \
#  && cmake .. -DCMAKE_INSTALL_PREFIX=${CONDA_PREFIX} -DBUILD_TESTS=${BUILD_TESTS:-OFF} \
#  && make install -j

# # Build and install cuGraph
# ONBUILD COPY cugraph/python /opt/rapids/cugraph/python
# ONBUILD RUN cd /opt/rapids/cugraph/python && python setup.py build_ext --inplace

# ONBUILD COPY cugraph/.git /opt/rapids/cugraph/.git
# ONBUILD RUN cd /opt/rapids/cugraph/python && python setup.py install
