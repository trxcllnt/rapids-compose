#!/usr/bin/env bash

set -Eeo pipefail

cd "$RAPIDS_HOME"

####
# Merge the rapids projects' envs into one rapids.yml environment file
####
cat << EOF > rapids.yml
name: rapids
channels:
- rapidsai
- nvidia
- rapidsai-nightly
- conda-forge
- defaults
dependencies:
- cmake>=3.17.0
- cmake_setuptools
- python=${PYTHON_VERSION}
- pip:
  - ptvsd
  - pytest-xdist
EOF

CUDA_TOOLKIT_VERSION=${CONDA_CUDA_TOOLKIT_VERSION:-$CUDA_SHORT_VERSION};

if [ "$BUILD_RMM" = "YES" ]; then
  cat "$RMM_HOME/conda/environments/rmm_dev_cuda10.0.yml" \
    | sed -r "s/cudatoolkit=10.0/cudatoolkit=$CUDA_TOOLKIT_VERSION/g" \
    | sed -r "s!rapidsai/label/cuda10.0!rapidsai/label/cuda$CUDA_TOOLKIT_VERSION!g" \
    > rmm.yml
    RAPIDS_CONDA="$RAPIDS_CONDA rmm.yml"
fi

if [ "$BUILD_CUDF" = "YES" ]; then
cat "$CUDF_HOME/conda/environments/cudf_dev_cuda10.0.yml" \
  | sed -r "s/cudatoolkit=10.0/cudatoolkit=$CUDA_TOOLKIT_VERSION/g" \
  | sed -r "s!rapidsai/label/cuda10.0!rapidsai/label/cuda$CUDA_TOOLKIT_VERSION!g" \
  > cudf.yml
  RAPIDS_CONDA="$RAPIDS_CONDA cudf.yml"
fi

if [ "$BUILD_CUML" = "YES" ]; then
cat "$CUML_HOME/conda/environments/cuml_dev_cuda10.0.yml" \
  | sed -r "s/cudatoolkit=10.0/cudatoolkit=$CUDA_TOOLKIT_VERSION/g" \
  | sed -r "s!rapidsai/label/cuda10.0!rapidsai/label/cuda$CUDA_TOOLKIT_VERSION!g" \
  > cuml.yml
  RAPIDS_CONDA="$RAPIDS_CONDA cuml.yml"
fi

if [ "$BUILD_CUGRAPH" = "YES" ]; then
cat "$CUGRAPH_HOME/conda/environments/cugraph_dev_cuda10.0.yml" \
  | sed -r "s/cudatoolkit=10.0/cudatoolkit=$CUDA_TOOLKIT_VERSION/g" \
  | sed -r "s!rapidsai/label/cuda10.0!rapidsai/label/cuda$CUDA_TOOLKIT_VERSION!g" \
  > cugraph.yml
  RAPIDS_CONDA="$RAPIDS_CONDA cugraph.yml"
fi

if [ "$BUILD_CUSPATIAL" = "YES" ]; then
cat "$CUSPATIAL_HOME/conda/environments/cuspatial_dev_cuda10.0.yml" \
  | sed -r "s/cudatoolkit=10.0/cudatoolkit=$CUDA_TOOLKIT_VERSION/g" \
  | sed -r "s!rapidsai/label/cuda10.0!rapidsai/label/cuda$CUDA_TOOLKIT_VERSION!g" \
  > cuspatial.yml
  RAPIDS_CONDA="$RAPIDS_CONDA cuspatial.yml"
fi

if [ "$BUILD_BLAZINGSQL" = "YES" ]; then
  cat "$RAPIDS_HOME/extra/blazingsql/conda/recipes/blazingsql/meta.yaml" \
  | tail -n +21 \
  | sed -r "s/\{\{ cuda_version \}\}/$CUDA_TOOLKIT_VERSION/g" \
  | sed -r "s!\{\{ minor_version \}\}!$CUDA_TOOLKIT_VERSION!g" \
  > blazingsql.yml
  RAPIDS_CONDA="$RAPIDS_CONDA blazingsql.yml $RAPIDS_HOME/compose/etc/extra/blazingsql/blazingdb-requirements.yml"
fi

conda-merge $RAPIDS_CONDA > merged.yml

# Strip out cmake + the rapids packages, and save the combined environment
cat merged.yml \
  | grep -v -P '^(.*?)\-(.*?)(rmm|cudf|dask-cudf|cugraph|cuspatial|nvstrings)(.*?)$' \
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
- nvidia
- rapidsai-nightly
- numba
- conda-forge
- defaults
dependencies:
- bokeh
- dask-labextension
- dask-ml
- ipython=${IPYTHON_VERSION:-"7.3.0"}
- jupyterlab=1.0.9
- matplotlib
- networkx
- nodejs
- scikit-learn
- scipy
- seaborn
- tensorflow
- umap-learn
- pip:
  - graphistry
  - git+https://github.com/jacobtomlinson/jupyterlab-nvdashboard.git
EOF

conda-merge rapids.yml notebooks.yml > merged.yml && mv merged.yml notebooks.yml
