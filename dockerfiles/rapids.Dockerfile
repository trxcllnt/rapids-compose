ARG CUDA_VERSION=9.2
ARG RAPIDS_VERSION=latest
ARG RAPIDS_NAMESPACE=anon
ARG LINUX_VERSION=ubuntu16.04
ARG CUDA_SHORT_VERSION=${CUDA_VERSION}
FROM nvidia/cuda:${CUDA_VERSION}-devel-${LINUX_VERSION}

ARG CUDA_SHORT_VERSION

ARG GCC_VERSION=5
ARG CXX_VERSION=5
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update -y --fix-missing && apt upgrade -y \
 && apt install -y \
    git \
    curl \
    # Need tzdata for the pyarrow<->ORC tests
    tzdata \
    ccache \
    apt-utils \
    libboost-all-dev \
    gcc-${GCC_VERSION} \
    g++-${CXX_VERSION} \
    python3 python3-pip \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG UID=1000
ARG GID=1000
ENV _UID=${UID}
ENV _GID=${GID}
ARG GOSU_VERSION=1.11
ARG TINI_VERSION=v0.18.0

ARG PYTHON_VERSION=3.7
ENV PYTHON_VERSION="$PYTHON_VERSION"
ENV CUDA_SHORT_VERSION="$CUDA_SHORT_VERSION"
ENV CC="/usr/bin/gcc-$GCC_VERSION"
ENV CXX="/usr/bin/g++-$CXX_VERSION"

ARG PTVSD_LOG_DIR=/var/log/ptvsd
ENV PTVSD_LOG_DIR="$PTVSD_LOG_DIR"

ARG RAPIDS_HOME
ENV RAPIDS_HOME="$RAPIDS_HOME"
ENV COMPOSE_HOME="$RAPIDS_HOME/compose"
ENV CONDA_HOME="$COMPOSE_HOME/etc/conda"
ENV RMM_HOME="$RAPIDS_HOME/rmm"
ENV CUDF_HOME="$RAPIDS_HOME/cudf"
ENV CUGRAPH_HOME="$RAPIDS_HOME/cugraph"
ENV NOTEBOOKS_HOME="$RAPIDS_HOME/notebooks"
ENV NOTEBOOKS_EXTENDED_HOME="$RAPIDS_HOME/notebooks-extended"

RUN curl -s -L https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -o /usr/bin/tini && chmod +x /usr/bin/tini \
 # Add gosu so we can run our apps as a non-root user
 # https://denibertovic.com/posts/handling-permissions-with-docker-volumes/
 && curl -s -L https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64 -o /usr/local/sbin/gosu && chmod +x /usr/local/sbin/gosu \
 && mkdir -p /var/log "$PTVSD_LOG_DIR" "$RAPIDS_HOME" "$CONDA_HOME" \
             /home/rapids /home/rapids/.conda /home/rapids/notebooks \
 # Symlink to root so we have an easy entrypoint from external scripts
 && ln -s "$RAPIDS_HOME" /rapids \
 # Create a rapids user with the same GID/UID as your outside OS user,
 # so you own files created by the container when using volume mounts.
 && groupadd -g ${GID} rapids && useradd -u ${UID} -g rapids \
    # 1. Set up a rapids home directory
    # 2. Add this user to the tty group
    # 3. Assign bash as the login shell
    -d /home/rapids -G tty -s /bin/bash rapids \
 && chmod 0777 /tmp \
 && chown -R ${_UID}:${_GID} /home/rapids "$CONDA_HOME" \
 && chmod -R 0755 /var/log /home/rapids "$CONDA_HOME" "$PTVSD_LOG_DIR"

# Add conda environments and recipes
COPY --chown=rapids rmm/conda "$RMM_HOME/conda"
COPY --chown=rapids cudf/conda "$CUDF_HOME/conda"
COPY --chown=rapids cugraph/conda "$CUGRAPH_HOME/conda"

# avoid "OSError: library nvvm not found" error
ENV CUDA_HOME="/usr/local/cuda-$CUDA_SHORT_VERSION"

COPY --chown=rapids compose/etc/conda-merge.sh "$RAPIDS_HOME/compose/etc/conda-merge.sh"

RUN pip3 install --no-cache-dir conda-merge==0.1.4 \
 # Merge the conda environment dependencies lists
 && gosu rapids bash "$RAPIDS_HOME/compose/etc/conda-merge.sh"

ENV PATH="$CONDA_HOME/bin:$CUDA_HOME/bin:$PATH:/usr/bin"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$CUDA_HOME/lib64"
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib"
ENV LD_LIBRARY_PATH="$CONDA_HOME/lib:$LD_LIBRARY_PATH"
ENV LD_LIBRARY_PATH="$CONDA_HOME/envs/rapids/lib:$LD_LIBRARY_PATH"

# Expose VSCode debugger port
EXPOSE 5678

ARG BUILD_TESTS="OFF"
ENV BUILD_TESTS="$BUILD_TESTS"

ARG BUILD_BENCHMARKS="OFF"
ENV BUILD_BENCHMARKS="$BUILD_BENCHMARKS"

ARG CMAKE_BUILD_TYPE="Release"
ENV CMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"

# COPY --chown=rapids compose/etc/rapids/lint.sh "$RAPIDS_HOME/compose/etc/rapids/lint.sh"
# COPY --chown=rapids compose/etc/rapids/clean.sh "$RAPIDS_HOME/compose/etc/rapids/clean.sh"
# COPY --chown=rapids compose/etc/rapids/build.sh "$RAPIDS_HOME/compose/etc/rapids/build.sh"
# COPY --chown=rapids compose/etc/rapids/start.sh "$RAPIDS_HOME/compose/etc/rapids/start.sh"
# COPY --chown=rapids compose/etc/conda-merge.sh "$RAPIDS_HOME/compose/etc/conda-merge.sh"
# COPY --chown=rapids compose/etc/conda-install.sh "$RAPIDS_HOME/compose/etc/conda-install.sh"

ARG FRESH_CONDA_ENV=0
ENV FRESH_CONDA_ENV=$FRESH_CONDA_ENV

# Create a bashrc that preserves history
RUN bash -c "echo -e '\n\
shopt -s histappend;\n\
# export PS1=\"\W\$ \";\n\
export HISTCONTROL=ignoreboth;\n\
export HISTSIZE=INFINITE;\n\
export HISTFILESIZE=10000000;\n\
'" > /home/rapids/.bashrc && chown ${_UID}:${_GID} /home/rapids/.bashrc \
 \
 && bash -c "echo -e '#!/bin/bash -e\n\
exec \"$RAPIDS_HOME/compose/etc/rapids/start.sh\" \"\$@\"\n\
'" > /entrypoint.sh && chown ${_UID}:${_GID} /entrypoint.sh && chmod +x /entrypoint.sh

WORKDIR $RAPIDS_HOME

ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]

CMD ["compose/etc/rapids/build.sh"]
