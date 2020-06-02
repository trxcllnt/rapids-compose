ARG CUDA_VERSION=10.0
ARG RAPIDS_VERSION=latest
ARG RAPIDS_NAMESPACE=anon
FROM rapidsai/${RAPIDS_NAMESPACE}/rapids:cuda-${CUDA_VERSION:-10.0}

ARG IPYTHON_VERSION=7.3.0
ENV IPYTHON_VERSION=$IPYTHON_VERSION

RUN apt update -y --fix-missing && apt upgrade -y \
 && apt install -y graphviz \
 && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/* \
 \
 && bash -c "echo -e '#!/bin/bash -e\n\
exec \"$COMPOSE_HOME/etc/notebooks/start.sh\" \"\$@\"\n\
'" > /entrypoint.sh && chown ${_UID}:${_GID} /entrypoint.sh && chmod +x /entrypoint.sh

CMD ["jupyter-lab", "--ip=0.0.0.0", "--no-browser", "--NotebookApp.token=''"]
