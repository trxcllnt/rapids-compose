ARG CUDA_VERSION=9.2
ARG RAPIDS_VERSION=latest
ARG RAPIDS_NAMESPACE=anon
FROM rapidsai/${RAPIDS_NAMESPACE}/cuda:${RAPIDS_VERSION}

###
# Build librmm
###
COPY rmm/src ${RMM_HOME}/src
COPY rmm/cmake ${RMM_HOME}/cmake
COPY rmm/python ${RMM_HOME}/python
COPY rmm/include ${RMM_HOME}/include
COPY rmm/thirdparty ${RMM_HOME}/thirdparty
COPY rmm/CMakeLists.txt ${RMM_HOME}/CMakeLists.txt
RUN mkdir -p ${RMM_HOME}/build && cd ${RMM_HOME}/build \
 && cmake .. -DCMAKE_INSTALL_PREFIX=${RMM_ROOT} -DBUILD_TESTS=${BUILD_TESTS:-OFF} \
 && make install -j \
 && make rmm_python_cffi
