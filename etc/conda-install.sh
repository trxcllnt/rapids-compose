#!/usr/bin/env bash

set -Eeuo pipefail

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

mkdir -p "$CONDA_HOME/envs/$ENV_NAME/etc/conda/activate.d"

cat << EOF > "$CONDA_HOME/envs/$ENV_NAME/etc/conda/activate.d/env-vars.sh"
#!/bin/sh

set -Ee

mkdir -p "\$RMM_HOME/build"
mkdir -p "\$CUDF_HOME/cpp/build"
mkdir -p "\$CUGRAPH_HOME/cpp/build"
mkdir -p "\$CONDA_PREFIX/include/libcudf"

export RMM_INCLUDE="\$RMM_HOME/include"
export CUDF_INCLUDE="\$CUDF_HOME/cpp/include"
export NVSTRINGS_INCLUDE="\$CUDF_HOME/cpp/include"
export CUGRAPH_INCLUDE="\$CUGRAPH_HOME/cpp/include"
export COMPOSE_INCLUDE="\$COMPOSE_HOME/etc/rapids/include"

export RMM_ROOT="\$RMM_HOME/\`cpp-build-dir \$RMM_HOME\`"
export CUDF_ROOT="\$CUDF_HOME/cpp/\`cpp-build-dir \$CUDF_HOME\`"
export NVSTRINGS_ROOT="\$CUDF_HOME/cpp/\`cpp-build-dir \$CUDF_HOME\`"
export CUGRAPH_ROOT="\$CUGRAPH_HOME/cpp/\`cpp-build-dir \$CUGRAPH_HOME\`"

make-symlink "\$RMM_ROOT/include" "\$RMM_HOME/build/include"
make-symlink "\$CUDF_ROOT/include" "\$CUDF_HOME/cpp/build/include"
make-symlink "\$CUGRAPH_ROOT/include" "\$CUGRAPH_HOME/cpp/build/include"

make-symlink "\$RMM_ROOT" "\$RMM_HOME/build/\$(basename "\$RMM_ROOT")"
make-symlink "\$CUDF_ROOT" "\$CUDF_HOME/cpp/build/\$(basename "\$CUDF_ROOT")"
make-symlink "\$CUGRAPH_ROOT" "\$CUGRAPH_HOME/cpp/build/\$(basename "\$CUGRAPH_ROOT")"

export RMM_ROOT="\$RMM_HOME/build/\$(basename "\$RMM_ROOT")"
export CUDF_ROOT="\$CUDF_HOME/cpp/build/\$(basename "\$CUDF_ROOT")"
export NVSTRINGS_ROOT="\$CUDF_HOME/cpp/build/\$(basename "\$CUDF_ROOT")"
export CUGRAPH_ROOT="\$CUGRAPH_HOME/cpp/build/\$(basename "\$CUGRAPH_ROOT")"

export RMM_LIBRARY="\$RMM_ROOT/librmm.so"
export CUDF_LIBRARY="\$CUDF_ROOT/libcudf.so"
export NVSTRINGS_LIBRARY="\$NVSTRINGS_ROOT/libNVStrings.so"
export NVCATEGORY_LIBRARY="\$NVSTRINGS_ROOT/libNVCategory.so"
export NVTEXT_LIBRARY="\$NVSTRINGS_ROOT/libNVText.so"
export CUGRAPH_LIBRARY="\$CUGRAPH_ROOT/libcugraph.so"

make-symlink "\$RMM_INCLUDE/rmm" "\$CONDA_PREFIX/include/rmm"
make-symlink "\$CUDF_INCLUDE/cudf" "\$CONDA_PREFIX/include/cudf"
make-symlink "\$CUDF_ROOT/include/libcxx" "\$CONDA_PREFIX/include/libcudf/libcxx"
make-symlink "\$CUDF_ROOT/include/libcudacxx" "\$CONDA_PREFIX/include/libcudf/libcudacxx"
make-symlink "\$NVSTRINGS_INCLUDE/nvstrings" "\$CONDA_PREFIX/include/nvstrings"
make-symlink "\$CUGRAPH_INCLUDE" "\$CONDA_PREFIX/include/cugraph"

make-symlink "\$COMPOSE_HOME/etc/conda/envs/rapids/include/dlpack" "\$COMPOSE_INCLUDE/dlpack"

make-symlink "\$RMM_LIBRARY" "\$CONDA_PREFIX/lib/\$(basename \$RMM_LIBRARY)"
make-symlink "\$CUDF_LIBRARY" "\$CONDA_PREFIX/lib/\$(basename \$CUDF_LIBRARY)"
make-symlink "\$NVSTRINGS_LIBRARY" "\$CONDA_PREFIX/lib/\$(basename \$NVSTRINGS_LIBRARY)"
make-symlink "\$NVCATEGORY_LIBRARY" "\$CONDA_PREFIX/lib/\$(basename \$NVCATEGORY_LIBRARY)"
make-symlink "\$NVTEXT_LIBRARY" "\$CONDA_PREFIX/lib/\$(basename \$NVTEXT_LIBRARY)"
make-symlink "\$CUGRAPH_LIBRARY" "\$CONDA_PREFIX/lib/\$(basename \$CUGRAPH_LIBRARY)"

set +Ee;

EOF

chmod +x "$CONDA_HOME/envs/$ENV_NAME/etc/conda/activate.d/env-vars.sh"
