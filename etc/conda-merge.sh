#!/usr/bin/env bash

set -Eeo pipefail

cd /home/rapids

####
# Merge the rapids projects' envs into one rapids.yml environment file
####
cat << EOF > rapids.yml
name: rapids
channels:
- rapidsai/label/cuda${CUDA_SHORT_VERSION}
- nvidia/label/cuda${CUDA_SHORT_VERSION}
- rapidsai-nightly/label/cuda${CUDA_SHORT_VERSION}
- conda-forge
- defaults
dependencies:
- cython=0.29.13
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

cat "$CUGRAPH_HOME/conda/environments/cugraph_dev_cuda10.yml" \
  | sed -r "s/cudatoolkit=10.0/cudatoolkit=$CUDA_SHORT_VERSION/g" \
  | sed -r "s!rapidsai/label/cuda10.0!rapidsai/label/cuda$CUDA_SHORT_VERSION!g" \
  > cugraph.yml

conda-merge rmm.yml cudf.yml cugraph.yml rapids.yml > merged.yml

 # Strip out the rapids packages and save the combined environment
cat merged.yml \
  | grep -v -P '^(.*?)\-(.*?)(rmm|cudf|dask-cudf|cugraph|nvstrings)(.*?)$' \
  > rapids.yml

####
# Merge the rapids env with this hard-coded one here for notebooks
# env since the notebooks repos don't include theirs in the github repo
# Pulled from https://github.com/rapidsai/build/blob/d2acf98d0f069d3dad6f0e2e4b33d5e6dcda80df/generatedDockerfiles/Dockerfile.ubuntu-runtime#L45
####
cat << EOF > notebooks.yml
name: notebooks
channels:
- rapidsai/label/cuda${CUDA_SHORT_VERSION}
- rapidsai
- nvidia/label/cuda${CUDA_SHORT_VERSION}
- nvidia
- rapidsai-nightly/label/cuda${CUDA_SHORT_VERSION}
- rapidsai-nightly
- numba
- conda-forge
- anaconda
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
