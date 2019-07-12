ARG CUDA_VERSION=9.2
ARG RAPIDS_VERSION=latest
ARG RAPIDS_NAMESPACE=anon
FROM rapidsai/${RAPIDS_NAMESPACE}/rapids:${RAPIDS_VERSION}

ARG IPYTHON_VERSION=7.3.0

RUN apt update && apt install -y graphviz && rm -rf /var/lib/apt/lists/* /var/tmp/* /tmp/*

# Copy in pip requirements.txt
COPY --chown=rapids:rapids compose/etc/notebooks/requirements.txt /home/rapids/compose/etc/notebooks/requirements.txt

RUN pip install --no-cache-dir -r /home/rapids/compose/etc/notebooks/requirements.txt \
# Set Jupyter Dark as the default theme in the extension settings
# Doing this allows it to be overridden by ~/.jupyter/lab/user-settings
 && sed -i 's/"default": "JupyterLab Light"/"default": "JupyterLab Dark"/g' \
    /usr/local/share/jupyter/lab/schemas/\@jupyterlab/apputils-extension/themes.json

# Add notebooks and util scripts
# COPY --chown=rapids:rapids notebooks /home/rapids/notebooks/core
# COPY --chown=rapids:rapids notebooks-extended/data /home/rapids/notebooks/data
# COPY --chown=rapids:rapids notebooks-extended/ /home/rapids/notebooks/extended
# COPY --chown=rapids:rapids compose/etc/notebooks/.jupyter /home/rapids/.jupyter

WORKDIR /home/rapids/notebooks

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/sbin/gosu", "rapids"]

CMD ["nohup", "jupyter-lab", "--ip=0.0.0.0", "--no-browser", "--NotebookApp.token=''"]
