#!/usr/bin/env bash

set -Eeo pipefail

source "$RAPIDS_HOME/.bashrc"

export PATH="$CONDA_HOME/bin:\
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:\
$CUDA_HOME/bin"

# Create or remove ccache compiler symlinks
set-gcc-version $GCC_VERSION >/dev/null 2>&1;

# - ensure conda's installed
# - ensure the notebooks conda env is created/updated/activated
source "$COMPOSE_HOME/etc/conda-install.sh" notebooks

# activate the notebooks conda environment on bash login
echo "source \"$RAPIDS_HOME/compose/etc/bash-utils.sh && source activate notebooks && source \"$RAPIDS_HOME/.bashrc\"" > "$RAPIDS_HOME/.bash_login"

if [ "$FRESH_CONDA_ENV" = "1" ]; then
    # Install the dask and nvdashboard jupyterlab extensions
    jupyter labextension install dask-labextension jupyterlab-nvdashboard
    # Set Jupyter Dark as the default theme in the extension settings. Doing it
    # this way allows it to be overridden by ~/.jupyter/lab/user-settings, which
    # is mounted in from the outside at `compose/etc/notebooks/.jupyter`
    sed -i 's/"default": "JupyterLab Light"/"default": "JupyterLab Dark"/g' \
        "$CONDA_HOME/envs/notebooks/share/jupyter/lab/schemas/@jupyterlab/apputils-extension/themes.json"
fi

cd "$RAPIDS_HOME/notebooks"

RUN_CMD="$(echo $(eval "echo $@"))"

# Run with gosu because `docker-compose up` doesn't support the --user flag.
# see: https://github.com/docker/compose/issues/1532
if [ "$_UID:$_GID" != "$(id -u):$(id -g)" ]; then
    RUN_CMD="/usr/local/sbin/gosu $_UID:$_GID $RUN_CMD"
fi;

exec -l ${RUN_CMD}
