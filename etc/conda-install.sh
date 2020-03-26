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

source /home/rapids/.bashrc

# ensure conda's installed
if [[ -z `which conda` ]]; then
   curl -s -o /home/rapids/miniconda.sh -L https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
   chmod +x /home/rapids/miniconda.sh && /home/rapids/miniconda.sh -f -b -p "$CONDA_HOME" && rm /home/rapids/miniconda.sh
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

INSIDE__ENV_YML="/home/rapids/$ENV_NAME.yml"
# TODO: this assumes the conda env name is the same as the folder under `compose/etc/`
OUTSIDE_ENV_YML="$COMPOSE_HOME/etc/$ENV_NAME/$ENV_NAME.yml"

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

mkdir -p "$CONDA_HOME/envs/$ENV_NAME/etc/conda/activate.d"
mkdir -p "$CONDA_HOME/envs/$ENV_NAME/etc/conda/deactivate.d"

cat << EOF > "$CONDA_HOME/envs/$ENV_NAME/etc/conda/deactivate.d/env-vars.sh"
#!/bin/sh

export PATH="\$OLD_PATH"
export LD_LIBRARY_PATH="\$OLD_LD_LIBRARY_PATH"

unset OLD_PATH
unset OLD_LD_LIBRARY_PATH

EOF

cat << EOF > "$CONDA_HOME/envs/$ENV_NAME/etc/conda/activate.d/env-vars.sh"
#!/bin/sh

set -Ee

mkdir -p "\$RMM_HOME/build"
mkdir -p "\$CUDF_HOME/cpp/build"
mkdir -p "\$CUML_HOME/cpp/build"
mkdir -p "\$CUGRAPH_HOME/cpp/build"
mkdir -p "\$CUSPATIAL_HOME/cpp/build"
mkdir -p "\$CONDA_PREFIX/include/libcudf"

make-symlink "\$CONDA_HOME/envs" "\$COMPOSE_HOME/etc/conda/envs"

export RMM_INCLUDE="\$RMM_HOME/include"
export CUDF_INCLUDE="\$CUDF_HOME/cpp/include"
export CUDF_TEST_INCLUDE="\$CUDF_HOME/cpp"
export NVSTRINGS_INCLUDE="\$CUDF_HOME/cpp/include"
export CUML_INCLUDE="\$CUML_HOME/cpp/include"
export CUGRAPH_INCLUDE="\$CUGRAPH_HOME/cpp/include"
export CUSPATIAL_INCLUDE="\$CUSPATIAL_HOME/cpp/include"
export COMPOSE_INCLUDE="\$COMPOSE_HOME/etc/rapids/include"

export RMM_ROOT_ABS="\$RMM_HOME/\$(cpp-build-dir \$RMM_HOME)"
export CUDF_ROOT_ABS="\$CUDF_HOME/cpp/\$(cpp-build-dir \$CUDF_HOME)"
export NVSTRINGS_ROOT_ABS="\$CUDF_HOME/cpp/\$(cpp-build-dir \$CUDF_HOME)"
export CUML_ROOT_ABS="\$CUML_HOME/cpp/\$(cpp-build-dir \$CUML_HOME)"
export CUGRAPH_ROOT_ABS="\$CUGRAPH_HOME/cpp/\$(cpp-build-dir \$CUGRAPH_HOME)"
export CUSPATIAL_ROOT_ABS="\$CUSPATIAL_HOME/cpp/\$(cpp-build-dir \$CUSPATIAL_HOME)"

###
# Define the *_ROOT paths as the symlinks that point to the absolute build dirs. For example:
# 
# \`\`\`shell
# CUDF_ROOT="/home/rapids/cudf/cpp/build/debug"
# CUDF_ROOT_ABS="/home/rapids/cudf/cpp/build/cuda-10.0/some-git-branch/debug"
# 
## Symlink \`build/cuda-10.0/some-git-branch/debug\` to -> \`build/debug\`
# ln -n -s \$CUDF_ROOT_ABS \$CUDF_ROOT
# \`\`\`
###

export RMM_ROOT="\$RMM_HOME/build/\$(basename "\$RMM_ROOT_ABS")"
export CUDF_ROOT="\$CUDF_HOME/cpp/build/\$(basename "\$CUDF_ROOT_ABS")"
export NVSTRINGS_ROOT="\$CUDF_HOME/cpp/build/\$(basename "\$CUDF_ROOT_ABS")"
export CUML_ROOT="\$CUML_HOME/cpp/build/\$(basename "\$CUML_ROOT_ABS")"
export CUGRAPH_ROOT="\$CUGRAPH_HOME/cpp/build/\$(basename "\$CUGRAPH_ROOT_ABS")"
export CUSPATIAL_ROOT="\$CUSPATIAL_HOME/cpp/build/\$(basename "\$CUSPATIAL_ROOT_ABS")"
export CUML_BUILD_PATH="cpp/\$(cpp-build-dir \$CUML_HOME)"

export RMM_LIBRARY="\$RMM_ROOT/librmm.so"
export CUDF_LIBRARY="\$CUDF_ROOT/libcudf.so"
export CUDFTESTUTIL_LIBRARY="\$CUDF_ROOT/tests/libcudftestutil.a"
export NVSTRINGS_LIBRARY="\$NVSTRINGS_ROOT/libNVStrings.so"
export NVCATEGORY_LIBRARY="\$NVSTRINGS_ROOT/libNVCategory.so"
export NVTEXT_LIBRARY="\$NVSTRINGS_ROOT/libNVText.so"
export CUML_LIBRARY="\$CUML_ROOT/libcuml.so"
export CUMLXX_LIBRARY="\$CUML_ROOT/libcuml++.so"
export CUMLCOMMS_LIBRARY="\$CUML_ROOT/comms/std/libcumlcomms.so"
export CUGRAPH_LIBRARY="\$CUGRAPH_ROOT/libcugraph.so"
export CUSPATIAL_LIBRARY="\$CUSPATIAL_ROOT/libcuspatial.so"

export LIBCUDF_KERNEL_CACHE_PATH="\$(find-cpp-build-home \$CUDF_HOME)/.jitify-cache"

export PYTHONPATH="\
\$RMM_HOME/python:\
\$CUDF_HOME/python/nvstrings:\
\$CUDF_HOME/python/cudf:\
\$CUDF_HOME/python/dask_cudf:\
\$CUML_HOME/python:\
\$CUGRAPH_HOME/python:\
\$CUSPATIAL_HOME/python"

export OLD_LD_LIBRARY_PATH="\$LD_LIBRARY_PATH"

export LD_LIBRARY_PATH="\
\$CONDA_HOME/envs/rapids/lib:\
\$CONDA_HOME/envs/$ENV_NAME/lib:\
\$CONDA_HOME/lib:\$LD_LIBRARY_PATH:\
\$RMM_ROOT:\$NVSTRINGS_ROOT:\$CUDF_ROOT:\$CUML_ROOT:\$CUGRAPH_ROOT:\$CUSPATIAL_ROOT"

make-symlink "\$RMM_ROOT_ABS" "\$RMM_ROOT"
make-symlink "\$CUDF_ROOT_ABS" "\$CUDF_ROOT"
make-symlink "\$CUML_ROOT_ABS" "\$CUML_ROOT"
make-symlink "\$CUGRAPH_ROOT_ABS" "\$CUGRAPH_ROOT"
make-symlink "\$CUSPATIAL_ROOT_ABS" "\$CUSPATIAL_ROOT"

# make-symlink "\$RMM_ROOT/include" "\$RMM_HOME/build/include"
make-symlink "\$CUDF_ROOT/include" "\$CUDF_HOME/cpp/build/include"
# make-symlink "\$CUML_ROOT/include" "\$CUML_HOME/cpp/build/include"
# make-symlink "\$CUGRAPH_ROOT/include" "\$CUGRAPH_HOME/cpp/build/include"
# make-symlink "\$CUSPATIAL_ROOT/include" "\$CUSPATIAL_HOME/cpp/build/include"

make-symlink "\$RMM_INCLUDE/rmm" "\$CONDA_PREFIX/include/rmm"
make-symlink "\$CUDF_INCLUDE/cudf" "\$CONDA_PREFIX/include/cudf"
make-symlink "\$CUDF_ROOT/include/libcxx" "\$CONDA_PREFIX/include/libcudf/libcxx"
make-symlink "\$CUDF_ROOT/include/libcudacxx" "\$CONDA_PREFIX/include/libcudf/libcudacxx"
make-symlink "\$NVSTRINGS_INCLUDE/nvstrings" "\$CONDA_PREFIX/include/nvstrings"
make-symlink "\$CUML_INCLUDE" "\$CONDA_PREFIX/include/cuml"
make-symlink "\$CUGRAPH_INCLUDE" "\$CONDA_PREFIX/include/cugraph"
make-symlink "\$CUSPATIAL_INCLUDE" "\$CONDA_PREFIX/include/cuspatial"

make-symlink "\$COMPOSE_HOME/etc/conda/envs/rapids/include/dlpack" "\$COMPOSE_INCLUDE/dlpack"
make-symlink "\$CUML_HOME/cpp/comms/std/include/cuML_comms.hpp" "\$COMPOSE_HOME/etc/conda/envs/rapids/include/cuML_comms.hpp"

make-symlink "\$RMM_LIBRARY" "\$CONDA_PREFIX/lib/\$(basename \$RMM_LIBRARY)"
make-symlink "\$CUDF_LIBRARY" "\$CONDA_PREFIX/lib/\$(basename \$CUDF_LIBRARY)"
make-symlink "\$NVSTRINGS_LIBRARY" "\$CONDA_PREFIX/lib/\$(basename \$NVSTRINGS_LIBRARY)"
make-symlink "\$NVCATEGORY_LIBRARY" "\$CONDA_PREFIX/lib/\$(basename \$NVCATEGORY_LIBRARY)"
make-symlink "\$NVTEXT_LIBRARY" "\$CONDA_PREFIX/lib/\$(basename \$NVTEXT_LIBRARY)"
make-symlink "\$CUML_LIBRARY" "\$CONDA_PREFIX/lib/\$(basename \$CUML_LIBRARY)"
make-symlink "\$CUMLXX_LIBRARY" "\$CONDA_PREFIX/lib/\$(basename \$CUMLXX_LIBRARY)"
make-symlink "\$CUMLCOMMS_LIBRARY" "\$CONDA_PREFIX/lib/\$(basename \$CUMLCOMMS_LIBRARY)"
make-symlink "\$CUGRAPH_LIBRARY" "\$CONDA_PREFIX/lib/\$(basename \$CUGRAPH_LIBRARY)"
make-symlink "\$CUSPATIAL_LIBRARY" "\$CONDA_PREFIX/lib/\$(basename \$CUSPATIAL_LIBRARY)"

export OLD_PATH="\$PATH"
set +Ee;

EOF

chmod +x "$CONDA_HOME/envs/$ENV_NAME/etc/conda/activate.d/env-vars.sh"
chmod +x "$CONDA_HOME/envs/$ENV_NAME/etc/conda/deactivate.d/env-vars.sh"

cmake_ver="$($CONDA_HOME/envs/rapids/bin/cmake --version|head -n 1)"
cmake_ver="${cmake_ver##cmake version }"
cmake_ver_major=$(echo $cmake_ver | cut -d. -f1)
cmake_ver_minor=$(echo $cmake_ver | cut -d. -f2)

if [[ "$cmake_ver_major" != "3" || "$cmake_ver_minor" != "17" ]]; then
    return_to_dir="$PWD";
    CMAKE_VERSION="3.17.0";
    curl \
        -o /tmp/cmake-${CMAKE_VERSION}.tar.gz \
        -L https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz \
     && cd /tmp && tar -xvzf cmake-${CMAKE_VERSION}.tar.gz && cd /tmp/cmake-${CMAKE_VERSION} \
     && CC="/usr/bin/gcc-$GCC_VERSION" CXX="/usr/bin/g++-$CXX_VERSION" \
        ./bootstrap --system-curl --parallel=${PARALLEL_LEVEL} --prefix="$CONDA_HOME/envs/rapids" \
     && make install -j${PARALLEL_LEVEL} \
     && cd /tmp && rm -rf /tmp/cmake-${CMAKE_VERSION}* && cd $return_to_dir;
    rm -rf "$CONDA_HOME/envs/rapids/lib/libcurl.so"
    rm -rf "$CONDA_HOME/envs/rapids/lib/libcurl.so.4"
    make-symlink $(readlink -e /usr/lib/x86_64-linux-gnu/libcurl.so) "$CONDA_HOME/envs/rapids/lib/libcurl.so"
    make-symlink $(readlink -e /usr/lib/x86_64-linux-gnu/libcurl.so.4) "$CONDA_HOME/envs/rapids/lib/libcurl.so.4"
fi
