#!/bin/bash -e

set -o errexit

cd /home/rapids

# Merge the conda environment dependencies lists
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
