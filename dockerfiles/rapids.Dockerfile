ARG CUDA_VERSION=11.2.0
ARG RAPIDS_VERSION=latest
ARG RAPIDS_NAMESPACE=anon
ARG LINUX_VERSION=ubuntu16.04
ARG CUDA_SHORT_VERSION=${CUDA_VERSION}
FROM nvidia/cudagl:${CUDA_VERSION}-devel-${LINUX_VERSION}

ARG USE_FISH_SHELL
ARG CUDA_SHORT_VERSION

ARG GCC_VERSION=7
ENV GCC_VERSION=${GCC_VERSION}
ENV CXX_VERSION=${GCC_VERSION}
ENV DEBIAN_FRONTEND=noninteractive

RUN echo 'Acquire::HTTP::Proxy "http://172.17.0.1:3142";' >> /etc/apt/apt.conf.d/01proxy \
 && echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy \
 && apt update \
 && apt install --no-install-recommends -y \
    apt-utils apt-transport-https software-properties-common \
 && add-apt-repository -y ppa:git-core/ppa \
 # Needed to install compatible gcc 9/10 toolchains
 && add-apt-repository -y ppa:ubuntu-toolchain-r/test \
 # CUDA toolkit version usable to install `cuda-nsight-compute` and `cuda-nsight-systems` packages
 && NSIGHT_CUDA_VERSION=$(nvcc --version | head -n4 | tail -n1 | cut -d' ' -f5 | cut -d',' -f1 | sed "s/\./-/g") \
 && bash -c '\
if [[ "$USE_FISH_SHELL" == "YES" ]]; then \
    add-apt-repository -y ppa:fish-shell/release-3; \
fi' \
 && apt update \
 && apt install --no-install-recommends -y \
    jq ed git vim nano sudo curl wget entr \
    # CMake dependencies
    curl libssl-dev libcurl4-openssl-dev zlib1g-dev \
    # Need tzdata for the pyarrow<->ORC tests
    tzdata \
    graphviz \
    gcc-9 g++-9 \
    gcc-10 g++-10 \
    ninja-build \
    build-essential \
    python3 python3-pip \
    # for building cudf-java
    maven openjdk-8-jdk \
    # Install nsight-compute and nsight-systems
    nsight-compute-2020.3.1 \
    nsight-systems-2020.4.3 \
    # Not sure what this is but it seems important
    cuda-nsight-compute-${NSIGHT_CUDA_VERSION} \
    # This provides the `nsight-sys` GUI
    cuda-nsight-systems-${NSIGHT_CUDA_VERSION} \
    # Needed by `nsight-sys` GUI
    qt5-default \
    libgl1-mesa-dev \
    ca-certificates \
    libglib2.0-0 \
    libsqlite3-0 \
    xcb \
    xkb-data \
    openssh-client \
    dbus \
    fontconfig \
    gnupg \
    libfreetype6 \
    libx11-xcb1 \
    libxcb-glx0 \
    libxcb-xkb1 \
    libxcomposite1 \
    libxi6 \
    libxml2 \
    libxrender1 \
 && bash -c '\
if [[ "$USE_FISH_SHELL" == "YES" ]]; then \
    apt install --no-install-recommends -y fish; \
fi' \
 && apt autoremove -y \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Remove any existing gcc and g++ alternatives
RUN update-alternatives --remove-all cc  >/dev/null 2>&1 || true \
 && update-alternatives --remove-all c++ >/dev/null 2>&1 || true \
 && update-alternatives --remove-all gcc >/dev/null 2>&1 || true \
 && update-alternatives --remove-all g++ >/dev/null 2>&1 || true \
 && update-alternatives --remove-all gcov >/dev/null 2>&1 || true \
 # Install alternatives for gcc/g++/cc/c++/gcov
 && for x in 7 8 9 10; do \
    update-alternatives \
    --install /usr/bin/gcc gcc /usr/bin/gcc-${x} ${x}0 \
    --slave /usr/bin/cc cc /usr/bin/gcc-${x} \
    --slave /usr/bin/g++ g++ /usr/bin/g++-${x} \
    --slave /usr/bin/c++ c++ /usr/bin/g++-${x} \
    --slave /usr/bin/gcov gcov /usr/bin/gcov-${x}; \
 done \
 # Set gcc-${GCC_VERSION} as the default gcc
 && update-alternatives --set gcc /usr/bin/gcc-${GCC_VERSION}

ARG UID=1000
ARG GID=1000
ENV _UID=${UID}
ENV _GID=${GID}
ARG GOSU_VERSION=1.11
ARG TINI_VERSION=v0.18.0
ARG CMAKE_VERSION=3.17.0
ENV CMAKE_VERSION=${CMAKE_VERSION}

ARG PYTHON_VERSION=3.7
ENV PYTHON_VERSION="$PYTHON_VERSION"
ENV CUDA_SHORT_VERSION="$CUDA_SHORT_VERSION"
ENV CC="/usr/bin/gcc-$GCC_VERSION"
ENV CXX="/usr/bin/g++-$CXX_VERSION"

ARG PARALLEL_LEVEL=4
ENV PARALLEL_LEVEL=${PARALLEL_LEVEL}

# Install CMake
RUN curl -fsSL --compressed -o /tmp/cmake-$CMAKE_VERSION.tar.gz \
    "https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION/cmake-$CMAKE_VERSION.tar.gz" \
 && cd /tmp && tar -xvzf cmake-$CMAKE_VERSION.tar.gz && cd /tmp/cmake-$CMAKE_VERSION \
 && /tmp/cmake-$CMAKE_VERSION/bootstrap --system-curl --parallel=$PARALLEL_LEVEL \
 && make install -j$PARALLEL_LEVEL \
 # Install ccache
 && git clone https://github.com/ccache/ccache.git /tmp/ccache && cd /tmp/ccache \
 && git checkout -b rapids-compose-tmp e071bcfd37dfb02b4f1fa4b45fff8feb10d1cbd2 \
 && mkdir -p /tmp/ccache/build && cd /tmp/ccache/build \
 && cmake \
    -DENABLE_TESTING=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_LIBB2_FROM_INTERNET=ON \
    -DUSE_LIBZSTD_FROM_INTERNET=ON .. \
 && make ccache -j${PARALLEL_LEVEL} && make install -j$PARALLEL_LEVEL && cd / && rm -rf /tmp/ccache \
 # Uninstall CMake
 && cd /tmp/cmake-$CMAKE_VERSION && make uninstall -j$PARALLEL_LEVEL && cd / && rm -rf /tmp/cmake-$CMAKE_VERSION* \
 # Install tini
 && curl -s -L https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -o /usr/bin/tini && chmod +x /usr/bin/tini \
 # Add gosu so we can run our apps as a non-root user
 # https://denibertovic.com/posts/handling-permissions-with-docker-volumes/
 && curl -s -L https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64 -o /usr/local/sbin/gosu && chmod +x /usr/local/sbin/gosu

ARG RAPIDS_HOME
ARG COMPOSE_HOME
ENV RAPIDS_HOME="$RAPIDS_HOME"
ENV COMPOSE_HOME="$COMPOSE_HOME"
ENV CONDA_HOME="$COMPOSE_HOME/etc/conda/cuda_$CUDA_SHORT_VERSION"
ENV RMM_HOME="$RAPIDS_HOME/rmm"
ENV CUDF_HOME="$RAPIDS_HOME/cudf"
ENV CUML_HOME="$RAPIDS_HOME/cuml"
ENV CUGRAPH_HOME="$RAPIDS_HOME/cugraph"
ENV CUSPATIAL_HOME="$RAPIDS_HOME/cuspatial"
ENV NOTEBOOKS_CONTRIB_HOME="$RAPIDS_HOME/notebooks-contrib"

RUN mkdir -p /var/log "$RAPIDS_HOME" "$CONDA_HOME" \
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
 && chmod -R 0755 /var/log "$RAPIDS_HOME" "$CONDA_HOME" \
 && bash -c "echo -e '#!/bin/bash -e\n\
exec \"$COMPOSE_HOME/etc/rapids/start.sh\" \"\$@\"\n\
'" > /entrypoint.sh \
 && touch "$RAPIDS_HOME/.bashrc" && touch "$RAPIDS_HOME/.bash_history" \
 && chown ${_UID}:${_GID} /entrypoint.sh "$RAPIDS_HOME/.bashrc" "$RAPIDS_HOME/.bash_history" \
 && chmod +x /entrypoint.sh \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV NVCC="/usr/local/bin/nvcc"
ENV CC="/usr/local/bin/gcc-$GCC_VERSION"
ENV CXX="/usr/local/bin/g++-$CXX_VERSION"
# avoid "OSError: library nvvm not found" error
ENV CUDA_HOME="/usr/local/cuda"

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
