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
