#!/usr/bin/env bash

set -Eeo pipefail

ENV_NAME=${1:-""}
ENV_NAME="${ENV_NAME// }"

if [ "$ENV_NAME" = "" ]; then
    >&2 echo "conda-install.sh must be called with a conda environment name argument"
    exit 1
fi

# If old conda dir (not prefixed with cuda version), remove it and make a new prefixed one
if [ -d "$COMPOSE_HOME/etc/conda/bin" ]; then
    rm -rf "$COMPOSE_HOME/etc/conda";
fi

# If necessary install conda, then create or update the conda env

mkdir -p "$CONDA_HOME"

# ensure conda's installed
if [[ -z `which conda` ]]; then
   curl -s -o $RAPIDS_HOME/miniconda.sh -L https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
   chmod +x $RAPIDS_HOME/miniconda.sh && $RAPIDS_HOME/miniconda.sh -f -b -p "$CONDA_HOME" && rm $RAPIDS_HOME/miniconda.sh
   conda config --system --set always_yes yes
fi

####
# Diff the conda environment.yml file created when the container was built
# against the environment.yml that exists in the container's volume mount.
# 
# - If there isn't an environment.yml in the volume mount, do `conda env create`
# - If the environment.yml in the volume mount is different than the container's,
#   do `conda env update --prune`.
# - Otherwise if they match, do nothing
####

INSIDE__ENV_YML="$RAPIDS_HOME/$ENV_NAME.yml"
# TODO: this assumes the conda env name is the same as the folder under `compose/etc/`
OUTSIDE_ENV_YML="$COMPOSE_HOME/etc/$ENV_NAME/$ENV_NAME-$CUDA_SHORT_VERSION.yml"

touch $INSIDE__ENV_YML

# If no environment.yml outside the container, use the one from inside the container
[[ ! -f $OUTSIDE_ENV_YML ]] && cp $INSIDE__ENV_YML $OUTSIDE_ENV_YML

# Merge the conda envs from all the repos
"$COMPOSE_HOME/etc/conda-merge.sh"

CHANGED="$(diff -qw $OUTSIDE_ENV_YML $INSIDE__ENV_YML || true)"

FRESH_CONDA_ENV=${FRESH_CONDA_ENV:-0}

# if no directory for the conda env, create the conda env
if [ ! -d "$CONDA_HOME/envs/$ENV_NAME" ]; then
    FRESH_CONDA_ENV=1
    # create a new environment
    conda update -n base -c defaults conda
    conda env create -n $ENV_NAME --file $INSIDE__ENV_YML
    # copy the conda environment.yml from inside the container to the outside
    cp $INSIDE__ENV_YML $OUTSIDE_ENV_YML
# otherwise if the environment.yml inside/outside are different, update the existing conda env
elif [ -n "${CHANGED// }" ]; then
    FRESH_CONDA_ENV=1
    # print the diff to the console for debugging
    diff -wy $OUTSIDE_ENV_YML $INSIDE__ENV_YML || true
    # update the existing environment
    conda update -n base -c defaults conda
    conda env update -n $ENV_NAME --file $INSIDE__ENV_YML --prune
    # copy the conda environment.yml from inside the container to the outside
    cp $INSIDE__ENV_YML $OUTSIDE_ENV_YML
fi

export FRESH_CONDA_ENV

rm "$RAPIDS_HOME/rmm.yml" || true >/dev/null 2>&1;
rm "$RAPIDS_HOME/cudf.yml" || true >/dev/null 2>&1;
rm "$RAPIDS_HOME/cuml.yml" || true >/dev/null 2>&1;
rm "$RAPIDS_HOME/cugraph.yml" || true >/dev/null 2>&1;
rm "$RAPIDS_HOME/cuspatial.yml" || true >/dev/null 2>&1;
rm "$RAPIDS_HOME/rapids.yml" || true >/dev/null 2>&1;
rm "$RAPIDS_HOME/notebooks.yml" || true >/dev/null 2>&1;

mkdir -p "$CONDA_HOME/envs/$ENV_NAME/etc/conda/activate.d"
mkdir -p "$CONDA_HOME/envs/$ENV_NAME/etc/conda/deactivate.d"

cp  "$COMPOSE_HOME/etc/conda-activate.sh" \
    "$CONDA_HOME/envs/$ENV_NAME/etc/conda/activate.d/env-vars.sh"

chmod +x "$CONDA_HOME/envs/$ENV_NAME/etc/conda/activate.d/env-vars.sh"

cp  "$COMPOSE_HOME/etc/conda-deactivate.sh" \
    "$CONDA_HOME/envs/$ENV_NAME/etc/conda/deactivate.d/env-vars.sh"

chmod +x "$CONDA_HOME/envs/$ENV_NAME/etc/conda/deactivate.d/env-vars.sh"

# activate the $ENV_NAME conda environment
source activate $ENV_NAME
