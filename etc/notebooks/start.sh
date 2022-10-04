#!/usr/bin/env bash

set -Eeo pipefail

source "$RAPIDS_HOME/.bashrc"

# - ensure conda's installed
# - ensure the notebooks conda env is created/updated/activated
source "$COMPOSE_HOME/etc/conda-install.sh" notebooks

# activate the notebooks conda environment on bash login
echo "export CONDA_DEFAULT_ENV=notebooks \
   && source \"$RAPIDS_HOME/.bashrc\" >/dev/null 2>&1 \
   && source activate notebooks >/dev/null 2>&1" \
> "$RAPIDS_HOME/.bash_login"

if [ "$FRESH_CONDA_ENV" = "1" ]; then
    # Install the dask and nvdashboard jupyterlab extensions
    jupyter labextension install @jupyter-widgets/jupyterlab-manager
    jupyter labextension install dask-labextension
    # Set Jupyter Dark as the default theme in the extension settings. Doing it
    # this way allows it to be overridden by ~/.jupyter/lab/user-settings, which
    # is mounted in from the outside at `compose/etc/notebooks/.jupyter`
    sed -i 's/"default": "JupyterLab Light"/"default": "JupyterLab Dark"/g' \
        "$CONDA_HOME/envs/notebooks/share/jupyter/lab/schemas/@jupyterlab/apputils-extension/themes.json"
fi

# Symlink each project's notebooks folder into the home dir
# TODO: add notebooks for clx, cusignal, cuxfilter, and xgboost?
mkdir -p "$RAPIDS_HOME/notebooks/core"
for PROJ in cudf cugraph cuml cuspatial; do
    make-symlink "$RAPIDS_HOME/$PROJ/notebooks" "$RAPIDS_HOME/notebooks/core/$PROJ"
done

cd "$RAPIDS_HOME/notebooks"

exec -l "$@"
