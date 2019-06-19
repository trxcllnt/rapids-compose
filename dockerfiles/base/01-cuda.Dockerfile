ARG CUDA_VERSION=9.2
ARG LINUX_VERSION=ubuntu16.04
ARG CUDA_SHORT_VERSION=${CUDA_VERSION}

FROM nvidia/cuda:${CUDA_VERSION}-devel-${LINUX_VERSION} as cuda_base

ARG GCC_VERSION=7
ARG CXX_VERSION=7
ARG CUDA_SHORT_VERSION
ARG PYTHON_VERSION=3.7
ENV PYTHON_VERSION=$PYTHON_VERSION
ARG CMAKE_VERSION=3.14.5
ENV CMAKE_VERSION=$CMAKE_VERSION
ENV DEBIAN_FRONTEND=noninteractive

ENV CC=/usr/bin/gcc-${GCC_VERSION}
ENV CXX=/usr/bin/g++-${CXX_VERSION}

# avoid "OSError: library nvvm not found" error
ENV CUDA_HOME=/usr/local/cuda-${CUDA_SHORT_VERSION}
ENV NUMBAPRO_LIBDEVICE=${CUDA_HOME}/nvvm/libdevice
ENV NUMBAPRO_NVVM=${CUDA_HOME}/nvvm/lib64/libnvvm.so

RUN apt update -y --fix-missing \
 && apt upgrade -y \
 && apt install -y --no-install-recommends \
    git curl \
    apt-utils software-properties-common \
    libssl-dev build-essential libboost-all-dev \
    autoconf gcc-${GCC_VERSION} g++-${CXX_VERSION}

# Install cmake 3.12
RUN curl -L https://www.cmake.org/files/v3.14/cmake-3.14.5.tar.gz -o /usr/src/cmake-3.14.5.tar.gz \
 && cd /usr/src && tar -xvzf cmake-3.14.5.tar.gz \
 && cd cmake-3.14.5 && ./configure && make -j && make install \
 && cd / && rm -rf /usr/src/cmake-3.14.5

# Install python
RUN apt-add-repository ppa:deadsnakes/ppa \
 && apt install -y --no-install-recommends \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
 && curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
 && ln -s $(which python${PYTHON_VERSION}) /usr/local/bin/python3 \
 && ln -s $(which python${PYTHON_VERSION}) /usr/local/bin/python \
 && echo "python3 at $(which python3) version after alias: $(python3 --version)" \
 && echo "python at $(which python) version after alias: $(python --version)" \
 && python /tmp/get-pip.py \
 && echo "pip3 at $(which pip3) version after alias: $(pip3 --version)" \
 && echo "pip at $(which pip) version after alias: $(pip --version)" \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG CFFI_VERSION=1.11.5
ARG NUMBA_VERSION=0.42.0
ARG NUMPY_VERSION=1.16.0
ARG CYTHON_VERSION=0.29.1

# Install cudf setup requirements
RUN pip install --no-cache-dir \
    wheel cmake_setuptools \
    cffi==${CFFI_VERSION} \
    numba==${NUMBA_VERSION} \
    numpy==${NUMPY_VERSION} \
    cython==${CYTHON_VERSION}

WORKDIR /opt/rapids

ENV RMM_HOME=/opt/rapids/rmm
ENV CUDF_HOME=/opt/rapids/cudf
ENV CUGRAPH_HOME=/opt/rapids/cugraph
ENV CUSTRINGS_HOME=/opt/rapids/custrings

ENV PYNI_PATH=/usr/local
ENV RMM_ROOT=${PYNI_PATH}
ENV CUDF_ROOT=${PYNI_PATH}
ENV CUGRAPH_ROOT=${PYNI_PATH}
ENV CUSTRINGS_ROOT=${PYNI_PATH}
ENV NVSTRINGS_ROOT=${PYNI_PATH}
ENV RMM_INCLUDE=${RMM_ROOT}/include/rmm
ENV CUDF_INCLUDE=${CUDF_ROOT}/include/cudf
ENV CUGRAPH_INCLUDE=${CUGRAPH_ROOT}/include/cugraph
ENV CUSTRINGS_INCLUDE=${CUSTRINGS_ROOT}/include/nvstrings
ENV NVSTRINGS_INCLUDE=${NVSTRINGS_ROOT}/include/nvstrings
ENV RMM_HEADER=/opt/rapids/rmm/include/rmm/rmm_api.h

ARG BUILD_TESTS=OFF

# Enables "source activate conda"
SHELL ["/bin/bash", "-c"]

COPY rmm/include /opt/rapids/rmm/include
