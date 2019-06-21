ARG CUDA_VERSION=9.2
ARG RAPIDS_VERSION=latest
ARG RAPIDS_NAMESPACE=anon
FROM rapidsai/${RAPIDS_NAMESPACE}/rapids:${RAPIDS_VERSION}

ARG IPYTHON_VERSION=7.3.0

RUN apt update \
 && apt install -y graphviz \
 && pip install --no-cache-dir \
    bokeh \
    scipy \
    jinja2 \
    seaborn \
    networkx \
    jupyterlab \
    matplotlib \
    scikit-learn \
    python-louvain \
    ipython==${IPYTHON_VERSION} \
    graphviz graphistry mockito kaggle \
 && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

# Add notebooks and util scripts
COPY --chown=rapids:rapids notebooks /home/rapids/notebooks/core
COPY --chown=rapids:rapids notebooks-extended/data /home/rapids/notebooks/data
COPY --chown=rapids:rapids notebooks-extended/ /home/rapids/notebooks/extended

WORKDIR /home/rapids/notebooks

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/sbin/gosu", "rapids"]

CMD ["nohup", "jupyter-lab", "--ip=0.0.0.0", "--no-browser", "--NotebookApp.token=''"]
