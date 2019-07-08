ARG CUDA_VERSION=9.2
ARG RAPIDS_VERSION=latest
ARG RAPIDS_NAMESPACE=anon
ARG LINUX_VERSION=ubuntu16.04
ARG CUDA_SHORT_VERSION=${CUDA_VERSION}

###
# RAPIDS runtime container
###
# FROM nvidia/cuda:${CUDA_VERSION}-runtime-${LINUX_VERSION}
FROM nvidia/cuda:${CUDA_VERSION}-devel-${LINUX_VERSION}

ARG CUDA_SHORT_VERSION
ARG PYTHON_VERSION=3.7
ENV PYTHON_VERSION=$PYTHON_VERSION
ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-c"]

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

# avoid "OSError: library nvvm not found" error
ENV CUDA_HOME=/usr/local/cuda-${CUDA_SHORT_VERSION}
ENV NUMBAPRO_LIBDEVICE=${CUDA_HOME}/nvvm/libdevice
ENV NUMBAPRO_NVVM=${CUDA_HOME}/nvvm/lib64/libnvvm.so
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$CUDA_HOME/lib64"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$CUDA_HOME/nvvm/lib64"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/rapids/rmm/build/lib"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/rapids/custrings/cpp/build/lib"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/rapids/custrings/python/build/lib.linux-x86_64-$PYTHON_VERSION"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/rapids/cudf/cpp/build/lib"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/rapids/cudf/python/cudf/build/lib.linux-x86_64-$PYTHON_VERSION"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/rapids/cugraph/cpp/build/lib"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/opt/rapids/cugraph/python/build/lib.linux-x86_64-$PYTHON_VERSION"

ENV PYTHONPATH="$PYTHONPATH:/opt/rapids/rmm/build/python"
ENV PYTHONPATH="$PYTHONPATH:/opt/rapids/custrings/python/build/lib.linux-x86_64-$PYTHON_VERSION"
ENV PYTHONPATH="$PYTHONPATH:/opt/rapids/cudf/python/cudf"
ENV PYTHONPATH="$PYTHONPATH:/opt/rapids/cudf/python/dask_cudf"
ENV PYTHONPATH="$PYTHONPATH:/opt/rapids/cugraph/python"

ARG UID=1000
ARG GID=1000
ARG GOSU_VERSION=1.11
ARG DASK_VERSION=2.0.0
ARG TINI_VERSION=v0.18.0
ARG CFFI_VERSION=1.11.5
ARG NUMBA_VERSION=0.43.0
ARG PANDAS_VERSION=0.23.4
ARG CYTHON_VERSION=0.29.10
ARG PYARROW_VERSION=0.12.1
ARG PTVSD_LOG_DIR=/var/log/ptvsd
ENV PTVSD_LOG_DIR=$PTVSD_LOG_DIR

RUN pip --no-cache-dir install \
    # install VSCode python debugger
    ptvsd \
    pytest \
    flake8 \
    msgpack \
    cffi==${CFFI_VERSION} \
    numba==${NUMBA_VERSION} \
    cython==${CYTHON_VERSION} \
    pandas==${PANDAS_VERSION} \
    pyarrow==${PYARROW_VERSION} \
    distributed>=${DASK_VERSION} \
    dask[dataframe]==${DASK_VERSION} \
 # cleanup
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 # Add tini to reap container subprocesses on exit
 && curl -L https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -o /usr/bin/tini && chmod +x /usr/bin/tini \
 # Add gosu so we can run our apps as a non-root user
 # https://denibertovic.com/posts/handling-permissions-with-docker-volumes/
 && curl -L https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64 -o /usr/local/sbin/gosu && chmod +x /usr/local/sbin/gosu \
 && mkdir -p /home/rapids ${PTVSD_LOG_DIR} \
 && mkdir -p /opt/rapids/cudf /opt/rapids/cugraph \
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
