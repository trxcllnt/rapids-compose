#!/usr/bin/env bash

set -Eeo pipefail

COMPOSE_HOME=$(dirname $(realpath "$0"))
COMPOSE_HOME=$(realpath "$COMPOSE_HOME/../")
RAPIDS_HOME=$(realpath "$COMPOSE_HOME/../")

cd "$RAPIDS_HOME"

select_version() {
    MSG="$1"
    DEFAULT="$2"
    SELECTION=""
    read -p "$MSG (default: $DEFAULT) " SELECTION </dev/tty
    if [ "$SELECTION" = "" ]; then
        SELECTION="$DEFAULT";
    fi
    echo "$SELECTION"
}

choose_bool_option() {
    MSG="$1"
    DEFAULT="$2"
    SELECTION=""
    while true; do
        read -p "$MSG (default: $DEFAULT) " SELECTION </dev/tty
        if [ "$SELECTION" = "" ]; then
            SELECTION="$DEFAULT";
        fi
        case $SELECTION in
            [Nn]* ) echo "NO"; break;;
            [Yy]* ) echo "YES"; break;;
            * ) >&2 echo "Please answer 'y' or 'n'";;
        esac
    done
}

join-list-contents() {
    local IFS='' delim=$1; shift; echo -n "$1"; shift; echo -n "${*/#/$delim}";
}

if [[ -n "$(which nvidia-smi)" ]]; then
    NUM_GPUS="$(nvidia-smi --list-gpus | wc -l)"
else
    NUM_GPUS="$(lspci | grep -E "(NVIDIA|AMD)" | grep "VGA" | wc -l)"
fi

GPUS_LIST="$(join-list-contents ', ' `seq 0 $((NUM_GPUS-1))`)"

CURRENT_CUDA_VERSION="11.5.0"
if [[ "$(which nvcc)" != "" ]]; then
    CURRENT_CUDA_VERSION="$(nvcc --version | head -n4 | tail -n1 | cut -d' ' -f5 | cut -d',' -f1)"
    # Append a patch version ".0" to the end of the major.minor string.
    CURRENT_CUDA_VERSION="${CURRENT_CUDA_VERSION}.0"
fi

echo "###
Configure RAPIDS environment \`.env\` file
###
";

if [ -f "$COMPOSE_HOME/.env" ]; then
    USE_EXISTING_ENV=$(choose_bool_option "Found config file at \"$COMPOSE_HOME/.env\"

Would you like me to reuse your existing config? (y/n)" "YES")
    if [[ "$USE_EXISTING_ENV" == "YES" ]]; then
        set -a && . "$COMPOSE_HOME/.env" && set +a
    fi
    echo ""
fi

GCC_VERSION=${GCC_VERSION:-$(select_version "Please enter your desired GCC version (9/10/11)" "9")}
CUDA_VERSION=${CUDA_VERSION:-$(select_version "Please enter your desired CUDA version (11.5.0)" "$CURRENT_CUDA_VERSION")}
PYTHON_VERSION=${PYTHON_VERSION:-$(select_version "Please enter your desired Python version (3.8/3.9)" "3.8")}
CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-$(select_version "Select RAPIDS CMake project built type (Debug/Release)" "Release")}
PARALLEL_LEVEL=${PARALLEL_LEVEL:-$(select_version "Select how many threads to use for parallel compilation (max: $(nproc))" "$(nproc --ignore=2)")}
NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES:-$(select_version "Select which GPU the container should use ($GPUS_LIST)" "0")}
BUILD_TESTS=${BUILD_TESTS:-$(select_version "Select whether to configure to build RAPIDS tests (ON/OFF)" "ON")}
BUILD_BENCHMARKS=${BUILD_BENCHMARKS:-$(select_version "Select whether to configure to build RAPIDS benchmarks (ON/OFF)" "ON")}

CONDA_CUDA_TOOLKIT_VERSION=$(echo $CUDA_VERSION | cut -d'.' -f1,2)

USE_CCACHE=${USE_CCACHE:-$(choose_bool_option "Use ccache for C++ builds? (y/n)" "YES")}

if [[ "$USE_CCACHE" == "YES" ]]; then
    CCACHE_MAXSIZE_MESSAGE="
Select the ccache max cache size.
The default value is 5G. The default suffix is G. Use 0 for no limit.
Available suffixes: k, M, G, T (decimal), and Ki, Mi, Gi, Ti (binary).
"
    CCACHE_MAXSIZE=${CCACHE_MAXSIZE:-$(select_version "$CCACHE_MAXSIZE_MESSAGE" "5G")}

fi

BUILD_RMM=${BUILD_RMM:-"YES"}
BUILD_CUDF=${BUILD_CUDF:-"YES"}
BUILD_RAFT=${BUILD_RAFT:-$(choose_bool_option "Build raft C++ and Cython? (y/n)" "NO")}
BUILD_CUML=${BUILD_CUML:-$(choose_bool_option "Build cuML C++ and Cython? (y/n)" "NO")}
BUILD_CUGRAPH=${BUILD_CUGRAPH:-$(choose_bool_option "Build cuGraph C++ and Cython? (y/n)" "NO")}
BUILD_CUSPATIAL=${BUILD_CUSPATIAL:-$(choose_bool_option "Build cuSpatial C++ and Cython? (y/n)" "NO")}

if [[ "$BUILD_CUML" == "NO" && "$BUILD_CUGRAPH" == "NO" && "$BUILD_CUSPATIAL" == "NO" ]]; then
    BUILD_CUDF=${BUILD_CUDF:-$(choose_bool_option "Build cuDF C++ and Cython? (y/n)" "YES")}
fi

if [[ "$BUILD_CUDF" == "NO" ]]; then
    BUILD_RMM=${BUILD_RMM:-$(choose_bool_option "Build rmm C++ and Cython? (y/n)" "YES")}
fi

compose_env_file() {
    echo "\
# Outside paths for docker volume mounts
RAPIDS_HOME=$RAPIDS_HOME
COMPOSE_HOME=$COMPOSE_HOME

# Build arguments
BASE_CONTAINER=gpuci/cuda
GCC_VERSION=$GCC_VERSION
CUDA_VERSION=$CUDA_VERSION
CONDA_CUDA_TOOLKIT_VERSION=$CONDA_CUDA_TOOLKIT_VERSION
PYTHON_VERSION=$PYTHON_VERSION
LINUX_VERSION=ubuntu20.04

# Whether to use ccache (https://ccache.dev/) to speed up gcc/nvcc build times
USE_CCACHE=$USE_CCACHE
# Whether to build C++/cuda tests/benchmarks during \`make rapids\` target
BUILD_TESTS=$BUILD_TESTS
BUILD_BENCHMARKS=$BUILD_BENCHMARKS
# Set to one of \"Debug\" \"Release\" \"MinSizeRel\" \"RelWithDebInfo\"
CMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE

###
# Select which RAPIDS projects to build
###
# Whether to build rmm C++ and Cython
BUILD_RMM=$BUILD_RMM
# Whether to build cuDF C++ and Cython (implies BUILD_RMM=YES)
BUILD_CUDF=$BUILD_CUDF
# Whether to build raft C++ and Cython
BUILD_RAFT=$BUILD_RAFT
# Whether to build cuML C++ and Cython (implies BUILD_CUDF=YES)
BUILD_CUML=$BUILD_CUML
# Whether to build cuGraph C++ and Cython (implies BUILD_CUDF=YES)
BUILD_CUGRAPH=$BUILD_CUGRAPH
# Whether to build cuSpatial C++ and Cython (implies BUILD_CUDF=YES)
BUILD_CUSPATIAL=$BUILD_CUSPATIAL
# Whether to disable rmm C++ deprecation warnings
DISABLE_DEPRECATION_WARNINGS=ON

# Select which GPU(s) the container will use when running tests/notebooks
NVIDIA_VISIBLE_DEVICES=$NVIDIA_VISIBLE_DEVICES

# Select how many threads to use for parallel compilation (e.g. \`make -j\${PARALLEL_LEVEL}\`)
PARALLEL_LEVEL=$PARALLEL_LEVEL

# Select the ccache max cache size.
# The default value is 5G. The default suffix is G. Use 0 for no limit.
# Available suffixes: k, M, G, T (decimal), and Ki, Mi, Gi, Ti (binary).
CCACHE_MAXSIZE=$CCACHE_MAXSIZE

# Set to YES to use the fish shell in the container (https://fishshell.com/)
USE_FISH_SHELL=${USE_FISH_SHELL:-NO}
"
}

if [ ! -f "$COMPOSE_HOME/.env" ]; then
    compose_env_file > "$COMPOSE_HOME/.env"
fi

CHANGED="$(diff -qwB "$COMPOSE_HOME/.env" <(compose_env_file) || true)"

if [ -n "${CHANGED// }" ]; then
    echo "Difference between current .env and proposed .env:";
    diff -wBy --suppress-common-lines "$COMPOSE_HOME/.env" <(compose_env_file) || true;
    while true; do
        read -p "Do you wish to overwrite your current .env file? (y/n) " yn </dev/tty
        case $yn in
            [Nn]* ) break;;
            [Yy]* ) compose_env_file > "$COMPOSE_HOME/.env"; break;;
            * ) echo "Please answer 'y' or 'n'";;
        esac
    done
fi
