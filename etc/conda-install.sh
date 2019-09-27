#!/usr/bin/env bash

set -e
set -o errexit

ENV_NAME=${1:-""}
ENV_NAME="${ENV_NAME// }"

if [ "$ENV_NAME" = "" ]; then
    >&2 echo "conda-install.sh must be called with a conda environment name argument"
    exit 1
fi

# If necessary install conda, then create or update the conda env

mkdir -p "$CONDA_HOME"

source /home/rapids/.bashrc

# ensure conda's installed
if [[ -z `which conda` ]]; then
   curl -s -o /home/rapids/miniconda.sh -L https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
   chmod +x /home/rapids/miniconda.sh && /home/rapids/miniconda.sh -f -b -p "$CONDA_HOME" && rm /home/rapids/miniconda.sh
   conda config --system --set always_yes yes && conda update --name base conda
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

INSIDE__ENV_YML="/home/rapids/$ENV_NAME.yml"
# TODO: this assumes the conda env name is the same as the folder under `compose/etc/`
OUTSIDE_ENV_YML="$RAPIDS_HOME/compose/etc/$ENV_NAME/$ENV_NAME.yml"

# If no environment.yml outside the container, use the one from inside the container
[[ ! -f $OUTSIDE_ENV_YML ]] && cp $INSIDE__ENV_YML $OUTSIDE_ENV_YML

# Merge the conda envs from all the repos
"$RAPIDS_HOME/compose/etc/conda-merge.sh"

CHANGED="$(diff -qw $INSIDE__ENV_YML $OUTSIDE_ENV_YML || true)"

FRESH_CONDA_ENV=${FRESH_CONDA_ENV:-0}

# if no directory for the conda env, create the conda env
if [ ! -d "$CONDA_HOME/envs/$ENV_NAME" ]; then
    FRESH_CONDA_ENV=1
    # create a new environment
    conda env create --name $ENV_NAME --file $INSIDE__ENV_YML
    # copy the conda environment.yml from inside the container to the outside
    cp $INSIDE__ENV_YML $OUTSIDE_ENV_YML
# otherwise if the environment.yml inside/outside are different, update the existing conda env
elif [ -n "${CHANGED// }" ]; then
    FRESH_CONDA_ENV=1
    # print the diff to the console for debugging
    diff -wy $INSIDE__ENV_YML $OUTSIDE_ENV_YML || true
    # update the existing environment
    conda env update --name $ENV_NAME --file $INSIDE__ENV_YML --prune
    # copy the conda environment.yml from inside the container to the outside
    cp $INSIDE__ENV_YML $OUTSIDE_ENV_YML
fi

export FRESH_CONDA_ENV
