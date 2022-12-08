#!/usr/bin/env bash

set -Eeo pipefail

if [ -z "$(which conda-merge)" ]; then
    pip install --no-cache-dir conda-merge==0.1.5;
fi

cd "$RAPIDS_HOME"

####
# Merge the rapids projects' envs into one rapids.yml environment file
####
cat << EOF > rapids.yml
name: rapids
channels:
- rapidsai
- rapidsai-nightly
- conda-forge
- nvidia
dependencies:
- cmake>=3.20
- cmake_setuptools
- pytest-xdist
- python=${PYTHON_VERSION}
- pip:
  - debugpy
EOF

CUDA_TOOLKIT_VERSION=${CONDA_CUDA_TOOLKIT_VERSION:-$CUDA_SHORT_VERSION};

find-env-file-version() {
    ENVS_DIR="$RAPIDS_HOME/$1/conda/environments"
    for YML in $ENVS_DIR/${1}_dev_cuda*.yml; do
        YML="${YML#$ENVS_DIR/$1}"
        YML="${YML#_dev_cuda}"
        echo "${YML%*.yml}"
        break;
    done
}

find-env-file-version-dfg() {
    # This function should be used for packages that have migrated to use
    # rapids-dependency-file-generator
    ENVS_DIR="$RAPIDS_HOME/$1/conda/environments"
    for YML in $ENVS_DIR/all_cuda-*_arch-x86_64.yaml; do
        YML="${YML#$ENVS_DIR/}"
        CONDA_ENV_CUDA_VER=$(echo ${YML} | sed 's/.*cuda-\([0-9][0-9]\)\([0-9]\)_.*/\1.\2/')
        echo "${CONDA_ENV_CUDA_VER}"
        break;
    done
}

replace-env-versions() {
    CONDA_ENV_CUDA_VER=$(find-env-file-version $1)
    cat "$RAPIDS_HOME/$1/conda/environments/$1_dev_cuda${CONDA_ENV_CUDA_VER}.yml" \
  | sed -r "s/cudatoolkit=${CONDA_ENV_CUDA_VER}/cudatoolkit=${CUDA_TOOLKIT_VERSION}/g" \
  | sed -r "s/nvcc_linux-64=${CONDA_ENV_CUDA_VER}/nvcc_linux-64=${CUDA_TOOLKIT_VERSION}/g" \
  | sed -r "s!rapidsai/label/cuda${CONDA_ENV_CUDA_VER}!rapidsai/label/cuda${CUDA_TOOLKIT_VERSION}!g" \
  | sed -r "s/- python[<>=,\.0-9]*$/- python=${PYTHON_VERSION}/g"
}

replace-env-versions-dfg() {
    # This function should be used for packages that have migrated to use
    # rapids-dependency-file-generator
    CONDA_ENV_CUDA_VER=$(find-env-file-version-dfg $1)
    cat "${RAPIDS_HOME}/$1/conda/environments/all_cuda-${CONDA_ENV_CUDA_VER//./}_arch-x86_64.yaml" \
  | sed -r "s/cudatoolkit=${CONDA_ENV_CUDA_VER}/cudatoolkit=${CUDA_TOOLKIT_VERSION}/g" \
  | sed -r "s/nvcc_linux-64=${CONDA_ENV_CUDA_VER}/nvcc_linux-64=${CUDA_TOOLKIT_VERSION}/g" \
  | sed -r "s!rapidsai/label/cuda${CONDA_ENV_CUDA_VER}!rapidsai/label/cuda${CUDA_TOOLKIT_VERSION}!g" \
  | sed -r "s/- python[<>=,\.0-9]*$/- python=${PYTHON_VERSION}/g"
}

YMLS=()
if [ $(should-build-rmm)       == true ]; then echo -e "$(replace-env-versions-dfg rmm)"   > rmm.yml       && YMLS+=(rmm.yml);       fi;
if [ $(should-build-raft)      == true ]; then echo -e "$(replace-env-versions-dfg raft)"      > raft.yml      && YMLS+=(raft.yml);      fi;
if [ $(should-build-cudf)      == true ]; then echo -e "$(replace-env-versions-dfg cudf)"  > cudf.yml      && YMLS+=(cudf.yml);      fi;
if [ $(should-build-cuml)      == true ]; then echo -e "$(replace-env-versions cuml)"      > cuml.yml      && YMLS+=(cuml.yml);      fi;
if [ $(should-build-cugraph)   == true ]; then echo -e "$(replace-env-versions cugraph)"   > cugraph.yml   && YMLS+=(cugraph.yml);   fi;
if [ $(should-build-cuspatial) == true ]; then echo -e "$(replace-env-versions-dfg cuspatial)" > cuspatial.yml && YMLS+=(cuspatial.yml); fi;
YMLS+=(rapids.yml)
conda-merge ${YMLS[@]} > merged.yml

# Strip out cmake + the rapids packages, and save the combined environment
cat merged.yml \
  | grep -v -P '^(.*?)\-(.*?)(rapids-build-env|rapids-notebook-env|rapids-doc-env|rapids-pytest-benchmark)(.*?)$' \
  | grep -v -P '^(.*?)\-(.*?)(rmm|cudf|libraft|pyraft|pylibraft|raft-dask|dask-cudf|cugraph|cuspatial|cuxfilter)(.*?)$' \
  | grep -v -P '^(.*?)\-(.*?)(\.git\@[^(main|master)])(.*?)$' \
  | grep -v -P '^(.*?)\-(.*?)(cmake=)(.*?)$' \
  > rapids.yml

####
# Merge the rapids env with this hard-coded one here for notebooks
# env since the notebooks repos don't include theirs in the github repo
# Pulled from https://github.com/rapidsai/build/blob/d2acf98d0f069d3dad6f0e2e4b33d5e6dcda80df/generatedDockerfiles/Dockerfile.ubuntu-runtime#L45
####
cat << EOF > notebooks.yml
name: notebooks
channels:
- rapidsai
- rapidsai-nightly
- conda-forge
- nvidia
dependencies:
- bokeh
- dask-labextension
- dask-ml
- ipython
# - ipython=${IPYTHON_VERSION:-"7.3.0"}
- ipywidgets
- jupyterlab
# - jupyterlab=1.0.9
- matplotlib
- networkx
- nodejs
- scikit-learn
- scipy
- seaborn
# - tensorflow
- umap-learn
- pip:
  - graphistry
EOF

conda-merge rapids.yml notebooks.yml > merged.yml && mv merged.yml notebooks.yml
