ARG CUDA_VERSION=9.2
ARG RAPIDS_VERSION=latest
ARG RAPIDS_NAMESPACE=anon
FROM rapidsai/${RAPIDS_NAMESPACE}/rmm:${RAPIDS_VERSION} AS rmm_base
FROM rapidsai/${RAPIDS_NAMESPACE}/cuda:${RAPIDS_VERSION}

ARG BUILD_TESTS=OFF

COPY --from=rmm_base ${RMM_ROOT}/lib/librmm.so ${RMM_ROOT}/lib/librmm.so
COPY --from=rmm_base ${RMM_ROOT}/include/rmm ${RMM_ROOT}/include/rmm

###
# Build custrings
###
COPY custrings/cpp ${CUSTRINGS_HOME}/cpp
COPY custrings/thirdparty ${CUSTRINGS_HOME}/thirdparty
RUN mkdir -p ${CUSTRINGS_HOME}/cpp/build && cd ${CUSTRINGS_HOME}/cpp/build \
 && cmake .. -DCMAKE_INSTALL_PREFIX=${CUSTRINGS_ROOT} -DBUILD_TESTS=${BUILD_TESTS:-OFF} \
 && make install -j

COPY custrings/python ${CUSTRINGS_HOME}/python
RUN cd ${CUSTRINGS_HOME}/python && python setup.py install
