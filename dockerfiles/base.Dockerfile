ARG CUDA_VERSION=9.2
ARG RAPIDS_VERSION=latest
ARG RAPIDS_NAMESPACE=anon
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
ENV CUDA_HOME="/usr/local/cuda"
ENV PATH="$PATH:$CUDA_HOME/bin"
ENV NUMBAPRO_LIBDEVICE="$CUDA_HOME/nvvm/libdevice"
ENV NUMBAPRO_NVVM="$CUDA_HOME/nvvm/lib64/libnvvm.so"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$CUDA_HOME/lib64"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$CUDA_HOME/nvvm/lib64"

RUN apt update -y --fix-missing \
 && apt upgrade -y \
 && apt install -y --no-install-recommends \
    git curl doxygen \
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

ARG UID=1000
ENV _UID=$UID

ARG GID=1000
ENV _GID=$GID

ARG RAPIDS_HOME
ENV RAPIDS_HOME="$RAPIDS_HOME"

ARG BUILD_TESTS=OFF
ENV BUILD_TESTS=$BUILD_TESTS

ARG BUILD_BENCHMARKS=OFF
ENV BUILD_BENCHMARKS=$BUILD_BENCHMARKS

ARG CMAKE_BUILD_TYPE=Release
ENV CMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE

ENV COMPOSE_HOME="$RAPIDS_HOME/compose"

ENV RMM_HOME="$RAPIDS_HOME/rmm"
ENV RMM_ROOT="$RMM_HOME"
ENV RMM_INCLUDE="$RMM_HOME/include"
ENV RMM_HEADER="$RMM_INCLUDE/rmm/rmm_api.h"

ENV CUDF_HOME="$RAPIDS_HOME/cudf"
ENV CUDF_ROOT="$CUDF_HOME/cpp"
ENV CUDF_INCLUDE="$CUDF_HOME/cpp/include"

ENV CUGRAPH_HOME="$RAPIDS_HOME/cugraph"
ENV CUGRAPH_ROOT="$CUGRAPH_HOME/cpp"
ENV CUGRAPH_INCLUDE="$CUGRAPH_HOME/cpp/include"

ENV NVSTRINGS_HOME="$RAPIDS_HOME/custrings"
ENV NVSTRINGS_ROOT="$NVSTRINGS_HOME/cpp"
ENV NVSTRINGS_INCLUDE="$NVSTRINGS_HOME/cpp/include"

ENV NOTEBOOKS_HOME="$RAPIDS_HOME/notebooks"
ENV NOTEBOOKS_EXTENDED_HOME="$RAPIDS_HOME/notebooks-extended"

WORKDIR $RAPIDS_HOME

# Copy in pip requirements.txt
COPY compose/etc/base/requirements.txt "$RAPIDS_HOME/compose/etc/base/requirements.txt"

# Install cudf setup requirements
RUN pip install --no-cache-dir -r "$RAPIDS_HOME/compose/etc/base/requirements.txt"

COPY compose/etc/build-rapids.sh "$RAPIDS_HOME/compose/etc/build-rapids.sh"
COPY compose/etc/check-style.sh "$RAPIDS_HOME/compose/etc/check-style.sh"

SHELL ["/bin/bash", "-c"]

CMD ["compose/etc/build-rapids.sh"]
