ARG CUDA_VERSION=11.8.0
ARG RAPIDS_NAMESPACE=anon
FROM rapidsai/${RAPIDS_NAMESPACE}/rapids:cuda-${CUDA_VERSION:-11.8.0}

RUN apt update --fix-missing \
 && apt install -y --no-install-recommends \
    graphviz \
 && apt autoremove -y \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 && bash -c "echo -e '#!/bin/bash -e\n\
exec \"\$COMPOSE_HOME/etc/notebooks/start.sh\" \"\$@\"\n\
'" > /entrypoint.sh && chown rapids:rapids /entrypoint.sh && chmod +x /entrypoint.sh

CMD ["jupyter-lab", "--ip=0.0.0.0", "--no-browser", "--NotebookApp.token=''"]
