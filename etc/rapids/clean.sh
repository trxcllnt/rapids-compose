#!/usr/bin/env bash

set -Eexo pipefail

cd "$RAPIDS_HOME"

update-environment-variables;

# If build clean, delete all build and runtime assets and caches
rm -rf "$RMM_HOME/`cpp-build-dir $RMM_HOME`" \
       "$CUDF_HOME/cpp/`cpp-build-dir $CUDF_HOME`" \
       "$CUML_HOME/cpp/`cpp-build-dir $CUML_HOME`" \
       "$CUGRAPH_HOME/cpp/`cpp-build-dir $CUGRAPH_HOME`" \
       "$RMM_HOME/python/dist" \
       "$RMM_HOME/python/build" \
       "$CUDF_HOME/python/.hypothesis" \
       "$CUDF_HOME/python/cudf/dist" \
       "$CUDF_HOME/python/cudf/build" \
       "$CUDF_HOME/python/cudf/.pytest_cache" \
       "$CUDF_HOME/python/nvstrings/dist" \
       "$CUDF_HOME/python/nvstrings/build" \
       "$CUDF_HOME/python/nvstrings/.pytest_cache" \
       "$CUDF_HOME/python/dask_cudf/dist" \
       "$CUDF_HOME/python/dask_cudf/build" \
       "$CUDF_HOME/python/dask_cudf/.pytest_cache" \
       "$CUML_HOME/python/dist" \
       "$CUML_HOME/python/build" \
       "$CUML_HOME/python/.hypothesis" \
       "$CUML_HOME/python/.pytest_cache" \
       "$CUML_HOME/python/external_repositories" \
       "$CUGRAPH_HOME/python/dist" \
       "$CUGRAPH_HOME/python/build" \
       "$CUGRAPH_HOME/python/.hypothesis" \
       "$CUGRAPH_HOME/python/.pytest_cache" \
 \
 && find "$RMM_HOME" -type f -name '*.pyc' -delete \
 && find "$CUDF_HOME" -type f -name '*.pyc' -delete \
 && find "$CUML_HOME" -type f -name '*.pyc' -delete \
 && find "$CUGRAPH_HOME" -type f -name '*.pyc' -delete \
 && find "$RMM_HOME" -type d -name '__pycache__' -delete \
 && find "$CUDF_HOME" -type d -name '__pycache__' -delete \
 && find "$CUML_HOME" -type d -name '__pycache__' -delete \
 && find "$CUGRAPH_HOME" -type d -name '__pycache__' -delete \
 \
 && find "$CUML_HOME/python/cuml" -type f -name '*.so' -delete \
 && find "$CUML_HOME/python/cuml" -type f -name '*.cpp' -delete \
 && find "$CUGRAPH_HOME/python/cugraph" -type f -name '*.so' -delete \
 && find "$CUGRAPH_HOME/python/cugraph" -type f -name '*.cpp' -delete \
 && find "$CUDF_HOME/python/cudf/cudf/_lib" -type f -name '*.so' -delete \
 && find "$CUDF_HOME/python/cudf/cudf/_lib" -type f -name '*.cpp' -delete \
 \
 && find "$RMM_HOME" -type d -name '.clangd' -print0 | xargs -0 -I {} /bin/rm -rf "{}" \
 && find "$CUDF_HOME" -type d -name '.clangd' -print0 | xargs -0 -I {} /bin/rm -rf "{}" \
 && find "$CUML_HOME" -type d -name '.clangd' -print0 | xargs -0 -I {} /bin/rm -rf "{}" \
 && find "$CUGRAPH_HOME" -type d -name '.clangd' -print0 | xargs -0 -I {} /bin/rm -rf "{}" \
 ;
