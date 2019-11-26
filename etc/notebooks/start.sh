#!/usr/bin/env bash

set -Eeuo pipefail

source /home/rapids/.bashrc
source "$COMPOSE_HOME/etc/bash-utils.sh"

# - ensure conda's installed
# - ensure the notebooks conda env is created/updated
source "$COMPOSE_HOME/etc/conda-install.sh" notebooks

# activate the notebooks conda environment
source activate notebooks

# activate the notebooks conda environment on bash login
echo "source activate notebooks" > /home/rapids/.bash_login

if [ "$FRESH_CONDA_ENV" = "1" ]; then
    # Install the rapids projects' source-builds into the conda notebooks env
    "$COMPOSE_HOME/etc/rapids/build.sh"
    # Install the dask and nvdashboard jupyterlab extensions
    jupyter labextension install dask-labextension jupyterlab-nvdashboard
    # Set Jupyter Dark as the default theme in the extension settings. Doing it
    # this way allows it to be overridden by ~/.jupyter/lab/user-settings, which
    # is mounted in from the outside at `compose/etc/notebooks/.jupyter`
    sed -i 's/"default": "JupyterLab Light"/"default": "JupyterLab Dark"/g' \
        "$CONDA_HOME/envs/notebooks/share/jupyter/lab/schemas/@jupyterlab/apputils-extension/themes.json"
fi

cd /home/rapids/notebooks

exec -l "$@"
