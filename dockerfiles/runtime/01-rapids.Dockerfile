ARG CUDA_VERSION=9.2
ARG RAPIDS_VERSION=latest
ARG RAPIDS_NAMESPACE=anon
ARG LINUX_VERSION=ubuntu16.04
ARG CUDA_SHORT_VERSION=${CUDA_VERSION}

FROM rapidsai/${RAPIDS_NAMESPACE}/cuda:${RAPIDS_VERSION} as cuda_base
FROM rapidsai/${RAPIDS_NAMESPACE}/rmm:${RAPIDS_VERSION} AS rmm_base
FROM rapidsai/${RAPIDS_NAMESPACE}/custrings:${RAPIDS_VERSION} AS custrings_base
FROM rapidsai/${RAPIDS_NAMESPACE}/cudf:${RAPIDS_VERSION} as cudf_base
FROM rapidsai/${RAPIDS_NAMESPACE}/cugraph:${RAPIDS_VERSION} as cugraph_base

###
# RAPIDS runtime container
###
FROM nvidia/cuda:${CUDA_VERSION}-runtime-${LINUX_VERSION}

ARG CUDA_SHORT_VERSION
ARG PYTHON_VERSION=3.7
ENV PYTHON_VERSION=$PYTHON_VERSION
ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-c"]

# avoid "OSError: library nvvm not found" error
ENV CUDA_HOME=/usr/local/cuda-${CUDA_SHORT_VERSION}
ENV NUMBAPRO_LIBDEVICE=${CUDA_HOME}/nvvm/libdevice
ENV NUMBAPRO_NVVM=${CUDA_HOME}/nvvm/lib64/libnvvm.so
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/cuda/lib64:/usr/local/lib

# Install python
RUN apt update -y --fix-missing \
 && apt upgrade -y \
 && apt install -y --no-install-recommends \
    curl \
    # Need tzdata for the pyarrow<->ORC tests
    tzdata \
    apt-utils \
    build-essential \
    software-properties-common \
 && apt-add-repository ppa:deadsnakes/ppa \
 # Install python
 && apt install -y --no-install-recommends \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python${PYTHON_VERSION}-distutils \
 && curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
 && ln -s $(which python${PYTHON_VERSION}) /usr/local/bin/python3 \
 && ln -s $(which python${PYTHON_VERSION}) /usr/local/bin/python \
 && echo "python3 at $(which python3) version after alias: $(python3 --version)" \
 && echo "python at $(which python) version after alias: $(python --version)" \
 && python /tmp/get-pip.py \
 && echo "pip3 at $(which pip3) version after alias: $(pip3 --version)" \
 && echo "pip at $(which pip) version after alias: $(pip --version)" \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# copy in required cuda libs and binaries
COPY --from=cuda_base ${CUDA_HOME}/bin/nvcc ${CUDA_HOME}/bin/nvcc
COPY --from=cuda_base ${CUDA_HOME}/nvvm/libdevice ${CUDA_HOME}/nvvm/libdevice
COPY --from=cuda_base ${CUDA_HOME}/nvvm/lib64/libnvvm.so ${CUDA_HOME}/nvvm/lib64/libnvvm.so

# copy in python env, rmm, cudf, custrings, and cugraph
COPY --from=rmm_base /opt/rapids/rmm /opt/rapids/rmm
COPY --from=custrings_base /opt/rapids/custrings /opt/rapids/custrings
COPY --from=cugraph_base /opt/rapids/cugraph /opt/rapids/cugraph
COPY --from=cudf_base /opt/rapids/cudf /opt/rapids/cudf

ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/rapids/rmm/build
ENV PYTHONPATH=${PYTHONPATH}:/opt/rapids/rmm/build/python

ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/rapids/custrings/cpp/build
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/rapids/custrings/python/build/lib.linux-x86_64-${PYTHON_VERSION}
ENV PYTHONPATH=${PYTHONPATH}:/opt/rapids/custrings/python/build/lib.linux-x86_64-${PYTHON_VERSION}

ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/rapids/cudf/cpp/build
ENV PYTHONPATH=${PYTHONPATH}:/opt/rapids/cudf/python

ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/rapids/cugraph/cpp/build
ENV PYTHONPATH=${PYTHONPATH}:/opt/rapids/cugraph/python

ARG UID=1000
ARG GID=1000
ARG GOSU_VERSION=1.11
ARG TINI_VERSION=v0.18.0
ARG CFFI_VERSION=1.11.5
ARG NUMBA_VERSION=0.41.0
ARG PANDAS_VERSION=0.23.4
ARG CYTHON_VERSION=0.29.10
ARG PYARROW_VERSION=0.12.1
ARG PTVSD_LOG_DIR=/var/log/ptvsd
ENV PTVSD_LOG_DIR=$PTVSD_LOG_DIR

RUN pip --no-cache-dir install \
    # install VSCode python debugger
    ptvsd \
    pytest \
    cffi==${CFFI_VERSION} \
    numba>=${NUMBA_VERSION} \
    cython==${CYTHON_VERSION} \
    pandas>=${PANDAS_VERSION} \
    pyarrow==${PYARROW_VERSION} \
 # cleanup
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 # https://github.com/pywren/runtimes/blob/5d6c8272fe595f16c226ae13cc6fc5b26db292ab/condaruntime.md
 # https://towardsdatascience.com/how-to-shrink-numpy-scipy-pandas-and-matplotlib-for-your-data-product-4ec8d7e86ee4
 # delete unit test dirs
 && echo "before delete unit test dirs: $(du -sh /usr/local/lib)" \
 && rm -rf $(find /usr/local/lib/python${PYTHON_VERSION} -type d | grep -e "/\(test\|tests\)$") \
 && echo " after delete unit test dirs: $(du -sh /usr/local/lib)" \
 # delete *.pyc files
 && echo "before delete *.pyc: $(du -sh /usr/local/lib)" \
 && find /usr/local/lib/python${PYTHON_VERSION} -type f -name '*.pyc' -delete \
 && echo " after delete *.pyc: $(du -sh /usr/local/lib)" \
 # strip shared libs (gcc)
 && echo "before strip shared libs: $(du -sh /usr/local/lib)" \
 && SOS=$(find /usr -type f -name '*.so') \
 && for SO in ${SOS}; do strip --strip-all ${SO} 2>/dev/null; done; \
    echo " after strip shared libs: $(du -sh /usr/local/lib)" \
 # Smoke test
 && python -c "from cudf.dataframe import DataFrame" \
 && python -c "from cudf import Series; \
    print(Series([1, 2], dtype='int8') + Series([3, 4], dtype='int16'))" \
 # Add tini to reap container subprocesses on exit
 && curl -L https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -o /usr/bin/tini && chmod +x /usr/bin/tini \
 # Add gosu so we can run our apps as a non-root user
 # https://denibertovic.com/posts/handling-permissions-with-docker-volumes/
 && curl -L https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64 -o /usr/local/sbin/gosu && chmod +x /usr/local/sbin/gosu \
 && mkdir -p /home/rapids ${PTVSD_LOG_DIR} \
 # Symlink dirs to root for compatibility with existing scripts
 && ln -s /opt/rapids /rapids \
 && ln -s /opt/rapids/cudf /cudf \
 && ln -s /opt/rapids/cugraph /cugraph \
 # Create a rapids user with the same GID/UID as your outside OS user,
 # so you own files created by the container when using volume mounts.
 && groupadd -g ${GID} rapids && useradd -u ${UID} -g rapids \
    # 1. Set up a rapids home directory
    # 2. Add this user to the tty group
    # 3. Assign bash as the login shell
    -d /home/rapids -G tty -s /bin/bash rapids \
 && chown -R rapids /rapids /cudf /cugraph /home/rapids \
 && chmod 0777 /tmp && chmod 0755 /var/log ${PTVSD_LOG_DIR}

# Expose VSCode debugger port
EXPOSE 5678

ENTRYPOINT [ "/usr/bin/tini", "--" ]

CMD ["/bin/bash"]
