#!/usr/bin/env bash

set -Eeo pipefail

cd /home/rapids

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

cat "$RMM_HOME/conda/environments/rmm_dev_cuda10.0.yml" \
  | sed -r "s/cudatoolkit=10.0/cudatoolkit=$CUDA_SHORT_VERSION/g" \
  | sed -r "s!rapidsai/label/cuda10.0!rapidsai/label/cuda$CUDA_SHORT_VERSION!g" \
  > rmm.yml

cat "$CUDF_HOME/conda/environments/cudf_dev_cuda10.0.yml" \
  | sed -r "s/cudatoolkit=10.0/cudatoolkit=$CUDA_SHORT_VERSION/g" \
  | sed -r "s!rapidsai/label/cuda10.0!rapidsai/label/cuda$CUDA_SHORT_VERSION!g" \
  > cudf.yml

cat "$CUML_HOME/conda/environments/cuml_dev_cuda10.0.yml" \
  | sed -r "s/cudatoolkit=10.0/cudatoolkit=$CUDA_SHORT_VERSION/g" \
  | sed -r "s!rapidsai/label/cuda10.0!rapidsai/label/cuda$CUDA_SHORT_VERSION!g" \
  > cuml.yml

cat "$CUGRAPH_HOME/conda/environments/cugraph_dev_cuda10.0.yml" \
  | sed -r "s/cudatoolkit=10.0/cudatoolkit=$CUDA_SHORT_VERSION/g" \
  | sed -r "s!rapidsai/label/cuda10.0!rapidsai/label/cuda$CUDA_SHORT_VERSION!g" \
  > cugraph.yml

cat "$CUSPATIAL_HOME/conda/environments/cuspatial_dev_cuda10.0.yml" \
  | sed -r "s/cudatoolkit=10.0/cudatoolkit=$CUDA_SHORT_VERSION/g" \
  | sed -r "s!rapidsai/label/cuda10.0!rapidsai/label/cuda$CUDA_SHORT_VERSION!g" \
  > cuspatial.yml

conda-merge rmm.yml cudf.yml cuml.yml cugraph.yml cuspatial.yml rapids.yml > merged.yml

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
  - git+https://github.com/jacobtomlinson/jupyterlab-nvdashboard.git
EOF

conda-merge rapids.yml notebooks.yml > merged.yml && mv merged.yml notebooks.yml
