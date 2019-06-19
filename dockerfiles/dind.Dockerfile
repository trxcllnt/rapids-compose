ARG DOCKER_VERSION
FROM docker:${DOCKER_VERSION}-dind

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
    apk add --no-cache zlib libgcc && \
    # Install docker-compose.
    # https://docs.docker.com/compose/install/
    DOCKER_COMPOSE_URL=https://github.com$(wget -q -O- https://github.com/docker/compose/releases/latest \
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

ENV _UID=1000
ENV _GID=1000

ENV CUDA_VERSION=9.2
ENV LINUX_VERSION=ubuntu18.04

ENV RAPIDS_VERSION=latest
ENV RAPIDS_NAMESPACE=anon

ENV COMPOSE_SOURCE=/opt/rapids/compose
ENV RMM_SOURCE=/opt/rapids/rmm
ENV CUDF_SOURCE=/opt/rapids/cudf
ENV CUGRAPH_SOURCE=/opt/rapids/cugraph
ENV CUSTRINGS_SOURCE=/opt/rapids/custrings
ENV NOTEBOOKS_SOURCE=/opt/rapids/notebooks
ENV NOTEBOOKS_EXTENDED_SOURCE=/opt/rapids/notebooks-extended

WORKDIR /opt/rapids

COPY etc/dind/.dockerignore .dockerignore

ENTRYPOINT ["/opt/rapids/compose/etc/dind/build.sh"]

CMD [""]
