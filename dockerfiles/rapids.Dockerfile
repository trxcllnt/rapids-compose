ARG BASE_CONTAINER=nvidia/cuda
ARG CUDA_VERSION=12.0.1
ARG RAPIDS_NAMESPACE=anon
ARG LINUX_VERSION=ubuntu22.04
ARG CUDA_SHORT_VERSION=${CUDA_VERSION}

FROM ${BASE_CONTAINER}:${CUDA_VERSION}-devel-${LINUX_VERSION}

ARG USE_FISH_SHELL
ARG CUDA_SHORT_VERSION

ENV CUDA_SHORT_VERSION="$CUDA_SHORT_VERSION"

RUN export DEBIAN_FRONTEND=noninteractive \
 && apt update \
 && apt install --no-install-recommends -y \
    pkg-config apt-utils apt-transport-https software-properties-common ca-certificates \
 && add-apt-repository --no-update -y ppa:git-core/ppa \
 # CUDA toolkit version usable to install `cuda-nsight-compute` and `cuda-nsight-systems` packages
 && NSIGHT_CUDA_VERSION="$(echo $CUDA_SHORT_VERSION | cut -d'.' -f1)-$(echo $CUDA_SHORT_VERSION | cut -d'.' -f2)" \
 && bash -c '\
if [[ "$USE_FISH_SHELL" == "YES" ]]; then \
    add-apt-repository --no-update -y ppa:fish-shell/release-3; \
fi' \
 && apt update \
 && apt install --no-install-recommends -y \
    jq ed git vim nano sudo curl wget entr less tar gzip xz-utils \
    # CMake dependencies
    curl libssl-dev libcurl4-openssl-dev zlib1g-dev \
    # Need tzdata for the pyarrow<->ORC tests
    tzdata \
    graphviz \
    ninja-build \
    # for building cudf-java
    maven openjdk-8-jdk openjdk-8-jdk-headless openjdk-8-jre openjdk-8-jre-headless \
    # Install nsight-compute and nsight-systems
    nsight-compute-2022.4.1 \
    nsight-systems-2022.4.2 \
    # Not sure what this is but it seems important
    cuda-nsight-compute-${NSIGHT_CUDA_VERSION} \
    # This provides the `nsight-sys` GUI
    cuda-nsight-systems-${NSIGHT_CUDA_VERSION} \
    # Needed by `nsight-sys` GUI
    qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
    libglvnd-dev libgl1-mesa-dev libegl1-mesa-dev libgles2-mesa-dev \
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
    libnuma1 \
    libnuma-dev \
 && bash -c '\
if [[ "$USE_FISH_SHELL" == "YES" ]]; then \
    apt install --no-install-recommends -y fish; \
fi' \
 # Clean up
 && apt autoremove -y \
 && rm -rf /tmp/* /var/tmp/* /var/cache/apt/* /var/lib/apt/lists/*

ARG RAPIDS_HOME
ARG COMPOSE_HOME

ARG TINI_VERSION=v0.19.0
ARG CCACHE_VERSION=4.6.3
ARG FIXUID_VERSION=0.5.1

ENV RAPIDS_HOME="$RAPIDS_HOME"
ENV COMPOSE_HOME="$COMPOSE_HOME"
ENV CONDA_HOME="$COMPOSE_HOME/etc/conda/cuda_$CUDA_SHORT_VERSION"
ENV RMM_HOME="$RAPIDS_HOME/rmm"
ENV CUDF_HOME="$RAPIDS_HOME/cudf"
ENV CUML_HOME="$RAPIDS_HOME/cuml"
ENV RAFT_HOME="$RAPIDS_HOME/raft"
ENV CUGRAPH_HOME="$RAPIDS_HOME/cugraph"
ENV CUSPATIAL_HOME="$RAPIDS_HOME/cuspatial"
ENV NOTEBOOKS_CONTRIB_HOME="$RAPIDS_HOME/notebooks-contrib"

    # Install tini
RUN curl -L https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -o /usr/bin/tini \
 && chown root:root /usr/bin/tini && chmod 0755 /usr/bin/tini \
 # Install ccache
 && curl -L https://github.com/ccache/ccache/releases/download/v${CCACHE_VERSION}/ccache-${CCACHE_VERSION}-linux-x86_64.tar.xz -o /tmp/ccache.tar.xz \
 && tar -C /usr/bin -f /tmp/ccache.tar.xz --wildcards --strip-components=1 -x */ccache \
 && chown root:root /usr/bin/ccache && chmod 0755 /usr/bin/ccache \
 # Set up ccache symlinks
 && ln -s -f /usr/bin/ccache /usr/local/sbin/gcc  \
 && ln -s -f /usr/bin/ccache /usr/local/sbin/g++  \
 && ln -s -f /usr/bin/ccache /usr/local/sbin/nvcc \
 ###################################################
 # Add non-root `rapids` user with passwordless sudo
 ###################################################
 && adduser \
    --gecos '' \
    --shell /bin/bash \
    --home "$RAPIDS_HOME" \
    --disabled-password rapids \
 && echo "rapids ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd \
 && mkdir -p \
    /var/log \
    "$CONDA_HOME" \
    "$RAPIDS_HOME/.conda" \
    "$RAPIDS_HOME/notebooks" \
 # Symlink to root so we have an easy entrypoint from external scripts
 && ln -s "$RAPIDS_HOME" /rapids \
 && chmod 0777 /tmp \
 && chown -R rapids:rapids "$RAPIDS_HOME" "$CONDA_HOME" \
 && chmod -R 0755 /var/log "$RAPIDS_HOME" "$CONDA_HOME" \
 && bash -c "echo -e '#!/bin/bash -e\n\
exec \"\$COMPOSE_HOME/etc/rapids/start.sh\" \"\$@\"\n\
'" > /entrypoint.sh \
 && touch "$RAPIDS_HOME/.bashrc" && touch "$RAPIDS_HOME/.bash_history" \
 && chown rapids:rapids /entrypoint.sh "$RAPIDS_HOME/.bashrc" "$RAPIDS_HOME/.bash_history" \
 && chmod +x /entrypoint.sh \
 ################################################################
 # Install fixuid
 # https://github.com/boxboat/fixuid#install-fixuid-in-dockerfile
 ################################################################
 && curl -L https://github.com/boxboat/fixuid/releases/download/v${FIXUID_VERSION}/fixuid-${FIXUID_VERSION}-linux-amd64.tar.gz -o /tmp/fixuid.tar.gz \
 && tar -C /usr/bin -xf /tmp/fixuid.tar.gz \
 && chown root:root /usr/bin/fixuid && chmod 4755 /usr/bin/fixuid \
 && mkdir -p /etc/fixuid \
 && bash -c "echo -e '\n\
user: rapids\n\
group: rapids\n\
paths:\n\
  - $RAPIDS_HOME\n\
'" > /etc/fixuid/config.yml \
 # Clean up
 && apt autoremove -y \
 && rm -rf /tmp/* /var/tmp/* /var/cache/apt/* /var/lib/apt/lists/*

ENV CC="/usr/local/sbin/gcc"
ENV CXX="/usr/local/sbin/g++"
ENV NVCC="/usr/local/sbin/nvcc"
# avoid "OSError: library nvvm not found" error
ENV CUDA_HOME="/usr/local/cuda"

ENV PATH="$CONDA_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$CUDA_HOME/bin"
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

WORKDIR "$RAPIDS_HOME"

ENTRYPOINT ["/usr/bin/tini", "--", "fixuid", "-q", "/entrypoint.sh"]

CMD ["bash"]
