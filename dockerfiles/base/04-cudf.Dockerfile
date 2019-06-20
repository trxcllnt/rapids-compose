ARG CUDA_VERSION=9.2
ARG RAPIDS_VERSION=latest
ARG RAPIDS_NAMESPACE=anon
ARG CUDA_SHORT_VERSION=${CUDA_VERSION}

FROM rapidsai/${RAPIDS_NAMESPACE}/rmm:${RAPIDS_VERSION} AS rmm_base
FROM rapidsai/${RAPIDS_NAMESPACE}/custrings:${RAPIDS_VERSION} AS custrings_base
FROM rapidsai/${RAPIDS_NAMESPACE}/cuda:${RAPIDS_VERSION}

ARG BUILD_TESTS=OFF

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
