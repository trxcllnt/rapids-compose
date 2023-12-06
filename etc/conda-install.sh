#!/usr/bin/env bash

set -Eeo pipefail

ENV_NAME=${1:-""}
ENV_NAME="${ENV_NAME// }"

if [ "$ENV_NAME" = "" ]; then
    >&2 echo "conda-install.sh must be called with a conda environment name argument"
    exit 1
fi

# If necessary install conda, then create or update the conda env

mkdir -p "$CONDA_HOME"

# ensure conda's installed
if [[ "$(which conda)" == "" ]]; then
    curl -s -o "$RAPIDS_HOME/mambaforge.sh" -L https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh
    chmod +x "$RAPIDS_HOME/mambaforge.sh" && "$RAPIDS_HOME/mambaforge.sh" -f -b -p "$CONDA_HOME" && rm "$RAPIDS_HOME/mambaforge.sh"
    conda config --system --set always_yes yes
    conda config --system --set changeps1 False
fi

if [[ "$(which mamba)" == "" ]]; then
    conda install -n base -c conda-forge mamba
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

CUDA_TOOLKIT_VERSION=${CONDA_CUDA_TOOLKIT_VERSION:-$CUDA_SHORT_VERSION};
export CONDA_OVERRIDE_CUDA=${CONDA_OVERRIDE_CUDA:-$CUDA_TOOLKIT_VERSION};

INSIDE__ENV_YML="$RAPIDS_HOME/$ENV_NAME.yml"
# TODO: this assumes the conda env name is the same as the folder under `compose/etc/`
OUTSIDE_ENV_YML="$COMPOSE_HOME/etc/$ENV_NAME/$ENV_NAME-$CUDA_TOOLKIT_VERSION.yml"

touch $INSIDE__ENV_YML

# If no environment.yml outside the container, use the one from inside the container
[[ ! -f $OUTSIDE_ENV_YML ]] && cp $INSIDE__ENV_YML $OUTSIDE_ENV_YML

# Merge the conda envs from all the repos
"$COMPOSE_HOME/etc/conda-merge.sh"

CHANGED="$(diff -qw $OUTSIDE_ENV_YML $INSIDE__ENV_YML || true)"

FRESH_CONDA_ENV=${FRESH_CONDA_ENV:-0}
RECREATE_CONDA_ENV=0

create-conda-env() {
    # create a new environment
    mamba update -n base -c conda-forge mamba
    mamba update -n base -c conda-forge conda
    mamba env create -n $ENV_NAME --file $INSIDE__ENV_YML
    # copy the conda environment.yml from inside the container to the outside
    cp $INSIDE__ENV_YML $OUTSIDE_ENV_YML
}

# if no directory for the conda env, create the conda env
if [ ! -d "$CONDA_HOME/envs/$ENV_NAME" ]; then
    FRESH_CONDA_ENV=1
    create-conda-env
# otherwise if the environment.yml inside/outside are different, update the existing conda env
elif [ -n "${CHANGED// }" ]; then
    (
        cd "$CONDA_HOME/envs/$ENV_NAME/include";
        rm rmm                || true >/dev/null 2>&1;
        rm kvikio             || true >/dev/null 2>&1;
        rm cudf               || true >/dev/null 2>&1;
        rm raft               || true >/dev/null 2>&1;
        rm raft.hpp           || true >/dev/null 2>&1;
        rm cuml               || true >/dev/null 2>&1;
        rm cugraph            || true >/dev/null 2>&1;
        rm cuspatial          || true >/dev/null 2>&1;
        rm libcudf/libcxx     || true >/dev/null 2>&1;
        rm libcudf/libcudacxx || true >/dev/null 2>&1;
    )
    FRESH_CONDA_ENV=1
    CONDA_ENV_UPDATE_FAILED=0
    # print the diff to the console for debugging
    diff -wy $OUTSIDE_ENV_YML $INSIDE__ENV_YML || true
    # update the existing environment
    mamba update -n base -c conda-forge mamba \
    && mamba update -n base -c conda-forge conda \
    && mamba env update -n $ENV_NAME --file $INSIDE__ENV_YML --prune \
    || CONDA_ENV_UPDATE_FAILED=1

    if [ "$CONDA_ENV_UPDATE_FAILED" -eq "0" ]; then
        # copy the conda environment.yml from inside the container to the outside
        cp $INSIDE__ENV_YML $OUTSIDE_ENV_YML
    else
        while true; do
            echo "Failed to update conda environment. Select how to proceed."
            echo "(Y) Continue anyway."
            echo "(N) Exit."
            echo "(R) Remove and re-create the conda environment from scratch instead of upgrading."
            read -p "Choose an action to continue (Y/N/R, default: Y) " CHOICE </dev/tty
            if [ "$CHOICE" = "" ]; then CHOICE="Y"; fi
            case $CHOICE in
                [Nn]* ) exit 1;;
                [Rr]* ) RECREATE_CONDA_ENV=1; break;;
                [Yy]* ) break;;
                * ) echo "Please answer Y/N/R."
            esac
        done
    fi
fi

if [ "$RECREATE_CONDA_ENV" -eq "1" ]; then
    mamba env remove --name $ENV_NAME
    FRESH_CONDA_ENV=1
    create-conda-env
fi

export FRESH_CONDA_ENV

rm -f "$RAPIDS_HOME/rmm.yml"       || true >/dev/null 2>&1;
rm -f "$RAPIDS_HOME/raft.yml"      || true >/dev/null 2>&1;
rm -f "$RAPIDS_HOME/kvikio.yml"    || true >/dev/null 2>&1;
rm -f "$RAPIDS_HOME/cudf.yml"      || true >/dev/null 2>&1;
rm -f "$RAPIDS_HOME/cuml.yml"      || true >/dev/null 2>&1;
rm -f "$RAPIDS_HOME/cugraph.yml"   || true >/dev/null 2>&1;
rm -f "$RAPIDS_HOME/cuspatial.yml" || true >/dev/null 2>&1;
rm -f "$RAPIDS_HOME/rapids.yml"    || true >/dev/null 2>&1;
rm -f "$RAPIDS_HOME/notebooks.yml" || true >/dev/null 2>&1;

mkdir -p "$CONDA_HOME/envs/$ENV_NAME/etc/conda/activate.d"
mkdir -p "$CONDA_HOME/envs/$ENV_NAME/etc/conda/deactivate.d"

cp  "$COMPOSE_HOME/etc/conda-activate.sh" \
    "$CONDA_HOME/envs/$ENV_NAME/etc/conda/activate.d/env-vars.sh"

chmod +x "$CONDA_HOME/envs/$ENV_NAME/etc/conda/activate.d/env-vars.sh"

cp  "$COMPOSE_HOME/etc/conda-deactivate.sh" \
    "$CONDA_HOME/envs/$ENV_NAME/etc/conda/deactivate.d/env-vars.sh"

chmod +x "$CONDA_HOME/envs/$ENV_NAME/etc/conda/deactivate.d/env-vars.sh"

if [ -z "$(grep changeps1 "$CONDA_HOME/.condarc" 2> /dev/null)" ]; then
    echo "changeps1: false" >> "$CONDA_HOME/.condarc"
fi

# activate the $ENV_NAME conda environment
source activate "$ENV_NAME"

update-environment-variables >/dev/null 2>&1;
