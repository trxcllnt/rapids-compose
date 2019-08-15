#!/bin/bash -e

 # An entrypoint that automatically creates, updates and activates the rapids conda env

mkdir -p "$CONDA_HOME"

source /home/rapids/.bashrc

if [[ -z `which conda` ]]; then
   curl -s -o /home/rapids/miniconda.sh -L https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
   chmod +x /home/rapids/miniconda.sh && /home/rapids/miniconda.sh -f -b -p "$CONDA_HOME" && rm /home/rapids/miniconda.sh
   conda config --system --set always_yes yes && conda update --name base conda
fi;

PREV_YML="$RAPIDS_HOME/compose/etc/rapids/rapids.yml"

[[ ! -f $PREV_YML ]] && cp /home/rapids/rapids.yml $PREV_YML

bash "$RAPIDS_HOME/compose/etc/conda-merge.sh"

FRESH_CONDA_ENV=${FRESH_CONDA_ENV:-0}
CHANGED="$(diff -q /home/rapids/rapids.yml $PREV_YML)"

if [ ! -d "$CONDA_HOME/envs/rapids" ]
then
    FRESH_CONDA_ENV=1
    conda env create --name rapids --file /home/rapids/rapids.yml python=$PYTHON_VERSION
    cp /home/rapids/rapids.yml $PREV_YML
elif [ -n "${CHANGED// }" ]
then
    FRESH_CONDA_ENV=1
    conda env update --name rapids --file /home/rapids/rapids.yml python=$PYTHON_VERSION --prune
    cp /home/rapids/rapids.yml $PREV_YML
fi

export FRESH_CONDA_ENV
source activate rapids
exec "$@"
