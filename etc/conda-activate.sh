#!/bin/sh

set -Ee

rm -rf "$CONDA_PREFIX"/include/{rmm,cudf,libcudf,cuml,cugraph,cuspatial}

mkdir -p "$RMM_HOME/build"
mkdir -p "$CUDF_HOME/cpp/build"
mkdir -p "$RAFT_HOME/cpp/build"
mkdir -p "$CUML_HOME/cpp/build"
mkdir -p "$CUGRAPH_HOME/cpp/build"
mkdir -p "$CUSPATIAL_HOME/cpp/build"
mkdir -p "$CONDA_PREFIX/include/libcudf"
mkdir -p "$CUDF_HOME/java/src/main/native/build"

make-symlink "$CONDA_HOME/bin" "$COMPOSE_HOME/etc/conda/bin"
make-symlink "$CONDA_HOME/envs" "$COMPOSE_HOME/etc/conda/envs"

export RMM_INCLUDE="$RMM_HOME/include"
export CUDF_INCLUDE="$CUDF_HOME/cpp/include"
export CUDF_TEST_INCLUDE="$CUDF_HOME/cpp"
export RAFT_INCLUDE="$RAFT_HOME/cpp/include"
export CUML_INCLUDE="$CUML_HOME/cpp/include"
export CUGRAPH_INCLUDE="$CUGRAPH_HOME/cpp/include"
export CUSPATIAL_INCLUDE="$CUSPATIAL_HOME/cpp/include"
export COMPOSE_INCLUDE="$COMPOSE_HOME/etc/rapids/include"
export CUDF_JNI_INCLUDE="$CUDF_HOME/java/src/main/native/include"

export RMM_ROOT_ABS="$RMM_HOME/$(cpp-build-dir $RMM_HOME)"
export CUDF_ROOT_ABS="$CUDF_HOME/cpp/$(cpp-build-dir $CUDF_HOME)"
export RAFT_ROOT_ABS="$RAFT_HOME/cpp/$(cpp-build-dir $RAFT_HOME)"
export CUML_ROOT_ABS="$CUML_HOME/cpp/$(cpp-build-dir $CUML_HOME)"
export CUGRAPH_ROOT_ABS="$CUGRAPH_HOME/cpp/$(cpp-build-dir $CUGRAPH_HOME)"
export CUSPATIAL_ROOT_ABS="$CUSPATIAL_HOME/cpp/$(cpp-build-dir $CUSPATIAL_HOME)"
export CUDF_JNI_ROOT_ABS="$CUDF_HOME/java/src/main/native/$(cpp-build-dir $CUDF_HOME)"

###
# Define the *_ROOT paths as the symlinks that point to the absolute build dirs. For example:
#
# ```shell
# CUDF_ROOT="$HOME/cudf/cpp/build/debug"
# CUDF_ROOT_ABS="$HOME/cudf/cpp/build/cuda-10.1/some-git-branch/debug"
#
## Symlink `build/cuda-10.1/some-git-branch/debug` to -> `build/debug`
# ln -n -s $CUDF_ROOT_ABS $CUDF_ROOT
# ```
###

export RMM_ROOT="$RMM_HOME/build/$(basename "$RMM_ROOT_ABS")"
export CUDF_ROOT="$CUDF_HOME/cpp/build/$(basename "$CUDF_ROOT_ABS")"
export RAFT_ROOT="$RAFT_HOME/cpp/build/$(basename "$RAFT_ROOT_ABS")"
export CUML_ROOT="$CUML_HOME/cpp/build/$(basename "$CUML_ROOT_ABS")"
export CUGRAPH_ROOT="$CUGRAPH_HOME/cpp/build/$(basename "$CUGRAPH_ROOT_ABS")"
export CUSPATIAL_ROOT="$CUSPATIAL_HOME/cpp/build/$(basename "$CUSPATIAL_ROOT_ABS")"
export CUDF_JNI_ROOT="$CUDF_HOME/java/src/main/native/build/$(basename "$CUDF_JNI_ROOT_ABS")"

export RMM_LIBRARY="$RMM_ROOT/librmm.so"
export CUDF_LIBRARY="$CUDF_ROOT/libcudf.so"
export CUDF_JNI_LIBRARY="$CUDF_JNI_ROOT/libcudfjni.so"
export CUDFTESTUTIL_LIBRARY="$CUDF_ROOT/libcudftestutil.a"
export NVTEXT_LIBRARY="$NVSTRINGS_ROOT/libNVText.so"
export CUML_LIBRARY="$CUML_ROOT/libcuml.so"
export CUMLXX_LIBRARY="$CUML_ROOT/libcuml++.so"
export CUMLCOMMS_LIBRARY="$CUML_ROOT/comms/std/libcumlcomms.so"
export CUGRAPH_LIBRARY="$CUGRAPH_ROOT/libcugraph.so"
export CUSPATIAL_LIBRARY="$CUSPATIAL_ROOT/libcuspatial.so"

export CUML_BUILD_PATH="$CUML_ROOT"
export CUGRAPH_BUILD_PATH="$CUGRAPH_ROOT"

export LIBCUDF_KERNEL_CACHE_PATH="$(find-cpp-build-home $CUDF_HOME)/.jitify-cache"

export PYTHONPATH="\
$RMM_HOME/python:\
$CUDF_HOME/python/cudf:\
$CUDF_HOME/python/dask_cudf:\
$RAFT_HOME/python:\
$CUML_HOME/python:\
$CUGRAPH_HOME/python/cugraph:\
$CUSPATIAL_HOME/python/cuspatial"

export OLD_PATH="${OLD_PATH:-$PATH}"
export OLD_LD_LIBRARY_PATH="${OLD_LD_LIBRARY_PATH:-$LD_LIBRARY_PATH}"

# export PATH="$CONDA_HOME/bin:\
# $CONDA_PREFIX/bin:\
# /usr/local/sbin:\
# /usr/local/bin:\
# /usr/sbin:\
# /usr/bin:\
# /sbin:\
# /bin:\
# $CUDA_HOME/bin"

export LD_LIBRARY_PATH="\
$CONDA_HOME/envs/rapids/lib:\
$CONDA_HOME/lib:\
$OLD_LD_LIBRARY_PATH:\
$RMM_ROOT:\
$CUDF_ROOT:\
$RAFT_ROOT:\
$CUML_ROOT:\
$CUGRAPH_ROOT:\
$CUSPATIAL_ROOT"

make-symlink "$RMM_ROOT_ABS" "$RMM_ROOT"
make-symlink "$CUDF_ROOT_ABS" "$CUDF_ROOT"
make-symlink "$RAFT_ROOT_ABS" "$RAFT_ROOT"
make-symlink "$CUML_ROOT_ABS" "$CUML_ROOT"
make-symlink "$CUGRAPH_ROOT_ABS" "$CUGRAPH_ROOT"
make-symlink "$CUSPATIAL_ROOT_ABS" "$CUSPATIAL_ROOT"
make-symlink "$CUDF_JNI_ROOT_ABS" "$CUDF_JNI_ROOT"

# make-symlink "$RMM_ROOT/include" "$RMM_HOME/build/include"
make-symlink "$CUDF_ROOT/include" "$CUDF_HOME/cpp/build/include"
# make-symlink "$CUML_ROOT/include" "$CUML_HOME/cpp/build/include"
# make-symlink "$CUGRAPH_ROOT/include" "$CUGRAPH_HOME/cpp/build/include"
# make-symlink "$CUSPATIAL_ROOT/include" "$CUSPATIAL_HOME/cpp/build/include"

make-symlink "$RMM_INCLUDE/rmm" "$CONDA_PREFIX/include/rmm"
make-symlink "$CUDF_INCLUDE/cudf" "$CONDA_PREFIX/include/cudf"
make-symlink "$CUDF_ROOT/include/libcxx" "$CONDA_PREFIX/include/libcudf/libcxx"
make-symlink "$CUDF_ROOT/include/libcudacxx" "$CONDA_PREFIX/include/libcudf/libcudacxx"
make-symlink "$RAFT_INCLUDE/raft" "$CONDA_PREFIX/include/raft"
make-symlink "$RAFT_INCLUDE/raft.hpp" "$CONDA_PREFIX/include/raft.hpp"
make-symlink "$CUML_INCLUDE/cuml" "$CONDA_PREFIX/include/cuml"
make-symlink "$CUGRAPH_INCLUDE/cugraph" "$CONDA_PREFIX/include/cugraph"
make-symlink "$CUSPATIAL_INCLUDE/cuspatial" "$CONDA_PREFIX/include/cuspatial"

make-symlink "$COMPOSE_HOME/etc/conda/envs/rapids/include/dlpack" "$COMPOSE_INCLUDE/dlpack"

make-symlink "$RMM_LIBRARY" "$CONDA_PREFIX/lib/$(basename $RMM_LIBRARY)"
make-symlink "$CUDF_LIBRARY" "$CONDA_PREFIX/lib/$(basename $CUDF_LIBRARY)"
make-symlink "$NVTEXT_LIBRARY" "$CONDA_PREFIX/lib/$(basename $NVTEXT_LIBRARY)"
make-symlink "$CUML_LIBRARY" "$CONDA_PREFIX/lib/$(basename $CUML_LIBRARY)"
make-symlink "$CUMLXX_LIBRARY" "$CONDA_PREFIX/lib/$(basename $CUMLXX_LIBRARY)"
make-symlink "$CUMLCOMMS_LIBRARY" "$CONDA_PREFIX/lib/$(basename $CUMLCOMMS_LIBRARY)"
make-symlink "$CUGRAPH_LIBRARY" "$CONDA_PREFIX/lib/$(basename $CUGRAPH_LIBRARY)"
make-symlink "$CUSPATIAL_LIBRARY" "$CONDA_PREFIX/lib/$(basename $CUSPATIAL_LIBRARY)"

env > /tmp/.last_env

set +Ee;
