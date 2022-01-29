FROM docker:stable-dind

###
# Install docker-compose
# https://github.com/wernight/docker-compose
###

RUN set -x && \
    apk add --no-cache -t .deps ca-certificates && \
    # Install glibc on Alpine (required by docker-compose) from
    # https://github.com/sgerrand/alpine-pkg-glibc
    # See also https://github.com/gliderlabs/docker-alpine/issues/11
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.29-r0/glibc-2.29-r0.apk && \
    apk add glibc-2.29-r0.apk && \
    rm glibc-2.29-r0.apk && \
    apk del --purge .deps

# Required for docker-compose to find zlib.
ENV LD_LIBRARY_PATH=/lib:/usr/lib

RUN set -x && \
    apk add --no-cache -t .deps ca-certificates && \
    # Required dependencies.
    apk add --no-cache zlib libgcc bash jq && \
    # Install docker-compose.
    # https://docs.docker.com/compose/install/
    DOCKER_COMPOSE_URL=https://github.com$(wget -q -O- https://github.com/docker/compose/releases/tag/1.29.2 \
        | grep -Eo 'href="[^"]+docker-compose-Linux-x86_64' \
        | sed 's/^href="//' \
        | head -n1) && \
    wget -q -O /usr/local/bin/docker-compose $DOCKER_COMPOSE_URL && \
    chmod a+rx /usr/local/bin/docker-compose && \
    \
    # Clean-up
    apk del --purge .deps && \
    \
    # Basic check it works
    docker-compose version

ARG RAPIDS_HOME
ARG COMPOSE_HOME
ENV RAPIDS_HOME="$RAPIDS_HOME"
ENV COMPOSE_HOME="$COMPOSE_HOME"
ENV RMM_HOME="$RAPIDS_HOME/rmm"
ENV CUDF_HOME="$RAPIDS_HOME/cudf"
ENV CUML_HOME="$RAPIDS_HOME/cuml"
ENV CUGRAPH_HOME="$RAPIDS_HOME/cugraph"
ENV CUSPATIAL_HOME="$RAPIDS_HOME/cuspatial"
ENV NOTEBOOKS_CONTRIB_HOME="$RAPIDS_HOME/notebooks-contrib"

ENV _UID=1000
ENV _GID=1000

ENV BASE_CONTAINER=nvidia/cuda
ENV CUDA_VERSION=11.5.0
ENV LINUX_VERSION=ubuntu18.04

ENV PYTHON_VERSION=3.7
ENV RAPIDS_NAMESPACE=anon

WORKDIR "$RAPIDS_HOME"

COPY etc/dind/ "$COMPOSE_HOME/etc/dind"
COPY etc/dind/.dockerignore "$RAPIDS_HOME/.dockerignore"

RUN cat "$RAPIDS_HOME/.dockerignore"

ENTRYPOINT ["$COMPOSE_HOME/etc/dind/build.sh"]

CMD ["$COMPOSE_HOME/etc/dind/print_build_context.sh"]
