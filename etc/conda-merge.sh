#!/bin/bash -e

set -o errexit

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
- cmake_setuptools
- python=${PYTHON_VERSION}
- pip:
  - ptvsd
  - pytest-xdist
EOF

cat "$RMM_HOME/conda/environments/rmm_dev_cuda$CUDA_SHORT_VERSION.yml" > rmm.yml

# Strip custring older cython version
cat "$NVSTRINGS_HOME/conda/environments/custrings_dev.yml" \
  | grep -v -P '^(.*?)\-(.*?)(cython)(.*?)$' > custrings.yml

cat "$CUDF_HOME/conda/environments/cudf_dev_cuda$CUDA_SHORT_VERSION.yml" > cudf.yml

CUGRAPH_CUDA_VER=$(echo $CUDA_SHORT_VERSION | tr -d '.' | cut -c 1-2)
cat "$CUGRAPH_HOME/conda/environments/cugraph_dev_cuda$CUGRAPH_CUDA_VER.yml" > cugraph.yml

conda-merge rmm.yml cudf.yml cugraph.yml custrings.yml rapids.yml 2>/dev/null 1> merged.yml

 # Strip out the rapids packages and save the combined environment
cat merged.yml \
  | grep -v -P '^(.*?)\-(.*?)(rmm|cudf|dask-cudf|cugraph|nvstrings|cudatoolkit)(.*?)$' \
  > rapids.yml

####
# Merge the rapids env with this hard-coded one here for notebooks
# env since the notebooks repos don't include theirs in the github repo
# Pulled from https://github.com/rapidsai/build/blob/d2acf98d0f069d3dad6f0e2e4b33d5e6dcda80df/generatedDockerfiles/Dockerfile.ubuntu-runtime#L45
####
cat << EOF > notebooks.yml
name: notebooks
channels:
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

conda-merge rapids.yml notebooks.yml 2>/dev/null 1> merged.yml && mv merged.yml notebooks.yml
