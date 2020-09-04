ARG CUDA_VERSION=10.0
ARG RAPIDS_VERSION=latest
ARG RAPIDS_NAMESPACE=anon
ARG LINUX_VERSION=ubuntu16.04
ARG CUDA_SHORT_VERSION=${CUDA_VERSION}
FROM nvidia/cudagl:${CUDA_VERSION}-devel-${LINUX_VERSION}

ARG CUDA_SHORT_VERSION

ARG GCC_VERSION=5
ENV GCC_VERSION=${GCC_VERSION}
ARG CXX_VERSION=5
ENV CXX_VERSION=${CXX_VERSION}
ENV DEBIAN_FRONTEND=noninteractive

RUN echo 'Acquire::HTTP::Proxy "http://172.17.0.1:3142";' >> /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy \
 && apt update -y --fix-missing && apt upgrade -y \
 && apt install -y software-properties-common \
 && add-apt-repository -y ppa:git-core/ppa \
 # Needed to install gcc-7 and 8 in Ubuntu 16.04
 && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
 && apt update -y \
 && apt install -y \
    jq ed git vim nano sudo curl wget entr \
    # CMake dependencies
    curl libssl-dev libcurl4-openssl-dev zlib1g-dev \
    # Need tzdata for the pyarrow<->ORC tests
    tzdata \
    apt-utils \
    gcc-5 g++-5 \
    gcc-7 g++-7 \
    gcc-8 g++-8 \
    ninja-build \
    doxygen graphviz \
    libboost-all-dev \
    python3 python3-pip \
    # Needed for nsight-gui
    ca-certificates \
    # for building cudf-java
    maven openjdk-8-jdk \
    apt-transport-https \
    libglib2.0-0 libsqlite3-0 \
    xcb xkb-data openssh-client \
    dbus fontconfig gnupg libfreetype6 \
    libx11-xcb1 libxcb-glx0 libxcb-xkb1 \
    libxcomposite1 libxi6 libxml2 libxrender1 \
 && bash -c '\
if [[ "$CUDA_SHORT_VERSION" == "10.1" ]]; then \
    apt install -y cuda-nsight-systems-10-1 nsight-systems-2019.3.7; \
elif [[ "$CUDA_SHORT_VERSION" == "10.2" ]]; then \
    apt install -y cuda-nsight-systems-10-2 nsight-systems-2019.5.2; \
elif [[ "$CUDA_SHORT_VERSION" == "11.0" ]]; then \
    apt install -y cuda-nsight-systems-11-0 nsight-systems-2020.2.5; \
fi' \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 0 \
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-5 0 \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 0 \
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-7 0 \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 0 \
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 0 \
 && update-alternatives --set gcc /usr/bin/gcc-${GCC_VERSION} \
 && update-alternatives --set g++ /usr/bin/g++-${CXX_VERSION}

ARG UID=1000
ARG GID=1000
ENV _UID=${UID}
ENV _GID=${GID}
ARG GOSU_VERSION=1.11
ARG TINI_VERSION=v0.18.0
ARG CMAKE_VERSION=3.17.2
ENV CMAKE_VERSION=${CMAKE_VERSION}
ARG CCACHE_VERSION=master
ENV CCACHE_VERSION=${CCACHE_VERSION}

ARG PYTHON_VERSION=3.7
ENV PYTHON_VERSION="$PYTHON_VERSION"
ENV CUDA_SHORT_VERSION="$CUDA_SHORT_VERSION"
ENV CC="/usr/bin/gcc-$GCC_VERSION"
ENV CXX="/usr/bin/g++-$CXX_VERSION"

ARG PARALLEL_LEVEL=4
ENV PARALLEL_LEVEL=${PARALLEL_LEVEL}

ARG PTVSD_LOG_DIR=/var/log/ptvsd
ENV PTVSD_LOG_DIR="$PTVSD_LOG_DIR"

ARG RAPIDS_HOME
ARG COMPOSE_HOME
ENV RAPIDS_HOME="$RAPIDS_HOME"
ENV COMPOSE_HOME="$COMPOSE_HOME"
ENV CONDA_HOME="$COMPOSE_HOME/etc/conda/cuda_$CUDA_SHORT_VERSION"
ENV RMM_HOME="$RAPIDS_HOME/rmm"
ENV CUDF_HOME="$RAPIDS_HOME/cudf"
ENV CUML_HOME="$RAPIDS_HOME/cuml"
ENV RAFT_HOME="$RAPIDS_HOME/raft"
ENV CUGRAPH_HOME="$RAPIDS_HOME/cugraph"
ENV CUSPATIAL_HOME="$RAPIDS_HOME/cuspatial"
ENV NOTEBOOKS_HOME="$RAPIDS_HOME/notebooks"
ENV NOTEBOOKS_EXTENDED_HOME="$RAPIDS_HOME/notebooks-contrib"

# RUN curl -s -L https://github.com/ccache/ccache/releases/download/v${CCACHE_VERSION}/ccache-${CCACHE_VERSION}.tar.gz -o ccache-${CCACHE_VERSION}.tar.gz \
#  && tar -xvzf ccache-${CCACHE_VERSION}.tar.gz && cd ccache-${CCACHE_VERSION} \
#  && ./configure && make install -j${PARALLEL_LEVEL} && cd - && rm -rf ./ccache-${CCACHE_VERSION} ./ccache-${CCACHE_VERSION}.tar.gz \

 # Install CMake
RUN curl -fsSLO --compressed "https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION.tar.gz" \
 && tar -xvzf cmake-$CMAKE_VERSION.tar.gz && cd cmake-$CMAKE_VERSION \
 && ./bootstrap --system-curl --parallel=${PARALLEL_LEVEL} && make install -j${PARALLEL_LEVEL} \
 && cd - && rm -rf ./cmake-$CMAKE_VERSION ./cmake-$CMAKE_VERSION.tar.gz \
 # Install ccache
 && git clone https://github.com/ccache/ccache.git /tmp/ccache && cd /tmp/ccache \
 && git checkout -b rapids-compose-tmp e071bcfd37dfb02b4f1fa4b45fff8feb10d1cbd2 \
 && mkdir -p /tmp/ccache/build && cd /tmp/ccache/build \
 && cmake \
    -DENABLE_TESTING=OFF \
    -DUSE_LIBB2_FROM_INTERNET=ON \
    -DUSE_LIBZSTD_FROM_INTERNET=ON .. \
 && make ccache -j${PARALLEL_LEVEL} && make install && cd / && rm -rf /tmp/ccache \
 # Install tini
 && curl -s -L https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -o /usr/bin/tini && chmod +x /usr/bin/tini \
 # Add gosu so we can run our apps as a non-root user
 # https://denibertovic.com/posts/handling-permissions-with-docker-volumes/
 && curl -s -L https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64 -o /usr/local/sbin/gosu && chmod +x /usr/local/sbin/gosu \
 && mkdir -p /var/log "$PTVSD_LOG_DIR" "$RAPIDS_HOME" "$CONDA_HOME" \
             "$RAPIDS_HOME" "$RAPIDS_HOME/.conda" "$RAPIDS_HOME/notebooks" \
 # Symlink to root so we have an easy entrypoint from external scripts
 && ln -s "$RAPIDS_HOME" /rapids \
 # Create a rapids user with the same GID/UID as your outside OS user,
 # so you own files created by the container when using volume mounts.
 && groupadd -g ${GID} rapids && useradd -u ${UID} -g rapids \
    # 1. Set up a rapids home directory
    # 2. Add this user to the tty group
    # 3. Assign bash as the login shell
    -d "$RAPIDS_HOME" -G tty -G sudo -s /bin/bash rapids \
 && echo rapids:rapids | chpasswd \
 && chmod 0777 /tmp \
 && chown -R ${_UID}:${_GID} "$RAPIDS_HOME" "$CONDA_HOME" \
 && chmod -R 0755 /var/log "$RAPIDS_HOME" "$CONDA_HOME" "$PTVSD_LOG_DIR" \
 && bash -c "echo -e '#!/bin/bash -e\n\
exec \"$COMPOSE_HOME/etc/rapids/start.sh\" \"\$@\"\n\
'" > /entrypoint.sh \
 && touch "$RAPIDS_HOME/.bashrc" && touch "$RAPIDS_HOME/.bash_history" \
 && chown ${_UID}:${_GID} /entrypoint.sh "$RAPIDS_HOME/.bashrc" "$RAPIDS_HOME/.bash_history" \
 && chmod +x /entrypoint.sh

ENV NVCC="/usr/local/bin/nvcc"
ENV CC="/usr/local/bin/gcc-$GCC_VERSION"
ENV CXX="/usr/local/bin/g++-$CXX_VERSION"
# avoid "OSError: library nvvm not found" error
ENV CUDA_HOME="/usr/local/cuda-$CUDA_SHORT_VERSION"

RUN pip3 install --no-cache-dir conda-merge==0.1.5

ENV PATH="$CONDA_HOME/bin:\
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:\
$CUDA_HOME/bin"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$CUDA_HOME/lib64:/usr/local/lib"

# Expose VSCode debugger port
EXPOSE 5678

ARG BUILD_TESTS="OFF"
ENV BUILD_TESTS="$BUILD_TESTS"

ARG BUILD_BENCHMARKS="OFF"
ENV BUILD_BENCHMARKS="$BUILD_BENCHMARKS"

ARG CMAKE_BUILD_TYPE="Release"
ENV CMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"

ARG FRESH_CONDA_ENV=0
ENV FRESH_CONDA_ENV=$FRESH_CONDA_ENV

WORKDIR $RAPIDS_HOME

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]

CMD ["bash"]
