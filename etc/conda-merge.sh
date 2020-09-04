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
- cmake>=3.17.0,<3.18
- cmake_setuptools
- python=${PYTHON_VERSION}
- pip:
  - ptvsd
  - pytest-xdist
EOF

CUDA_TOOLKIT_VERSION=${CONDA_CUDA_TOOLKIT_VERSION:-$CUDA_SHORT_VERSION};

cat "$RMM_HOME/conda/environments/rmm_dev_cuda10.0.yml" \
  | sed -r "s/cudatoolkit=10.0/cudatoolkit=$CUDA_TOOLKIT_VERSION/g" \
  | sed -r "s!rapidsai/label/cuda10.0!rapidsai/label/cuda$CUDA_TOOLKIT_VERSION!g" \
  > rmm.yml

cat "$CUDF_HOME/conda/environments/cudf_dev_cuda10.2.yml" \
  | sed -r "s/cudatoolkit=10.2/cudatoolkit=$CUDA_TOOLKIT_VERSION/g" \
  | sed -r "s!rapidsai/label/cuda10.2!rapidsai/label/cuda$CUDA_TOOLKIT_VERSION!g" \
  > cudf.yml

cat "$CUML_HOME/conda/environments/cuml_dev_cuda10.2.yml" \
  | sed -r "s/cudatoolkit=10.2/cudatoolkit=$CUDA_TOOLKIT_VERSION/g" \
  | sed -r "s!rapidsai/label/cuda10.2!rapidsai/label/cuda$CUDA_TOOLKIT_VERSION!g" \
  > cuml.yml

cat "$CUGRAPH_HOME/conda/environments/cugraph_dev_cuda10.2.yml" \
  | sed -r "s/cudatoolkit=10.2/cudatoolkit=$CUDA_TOOLKIT_VERSION/g" \
  | sed -r "s!rapidsai/label/cuda10.2!rapidsai/label/cuda$CUDA_TOOLKIT_VERSION!g" \
  > cugraph.yml

cat "$CUSPATIAL_HOME/conda/environments/cuspatial_dev_cuda10.2.yml" \
  | sed -r "s/cudatoolkit=10.2/cudatoolkit=$CUDA_TOOLKIT_VERSION/g" \
  | sed -r "s!rapidsai/label/cuda10.2!rapidsai/label/cuda$CUDA_TOOLKIT_VERSION!g" \
  > cuspatial.yml

conda-merge rmm.yml cudf.yml cuml.yml cugraph.yml cuspatial.yml rapids.yml > merged.yml

# Strip out cmake + the rapids packages, and save the combined environment
cat merged.yml \
  | grep -v -P '^(.*?)\-(.*?)(rapids-build-env|rapids-notebook-env|rapids-doc-env)(.*?)$' \
  | grep -v -P '^(.*?)\-(.*?)(rmm|cudf|dask-cudf|cugraph|cuspatial|nvstrings)(.*?)$' \
  | grep -v -P '^(.*?)\-(.*?)(cmake=)(.*?)$' \
  > rapids.yml
