#!/usr/bin/env bash

set -Eeo pipefail

cd $(dirname "$(realpath "$0")")/../../

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

echo "###
Configure RAPIDS environment \`.env\` file
###
";

vGCC=$(select_version "Please enter your desired GCC version" "5")
CUDA_VERSION=$(select_version "Please enter your desired CUDA version" "10.0")
PYTHON_VERSION=$(select_version "Please enter your desired Python version" "3.7")
LINUX_VERSION=$(select_version "Please enter your desired Linux container base" "ubuntu18.04")
BUILD_TESTS=$(select_version "Select whether to configure to build RAPIDS tests (ON/OFF)" "ON")
BUILD_BENCHMARKS=$(select_version "Select whether to configure to build RAPIDS benchmarks (ON/OFF)" "ON")
CMAKE_BUILD_TYPE=$(select_version "Select RAPIDS CMake project built type (Debug/Release)" "Release")
NVIDIA_VISIBLE_DEVICES=$(select_version "Select which GPU the container should use" "0")

compose_env_file() {
    echo "\
# Build arguments
RAPIDS_HOME=$PWD
GCC_VERSION=$vGCC
CXX_VERSION=$vGCC
CUDA_VERSION=$CUDA_VERSION
PYTHON_VERSION=$PYTHON_VERSION
LINUX_VERSION=$LINUX_VERSION

# Whether to build C++/cuda tests/benchmarks during \`make rapids\` target
BUILD_TESTS=$BUILD_TESTS
BUILD_BENCHMARKS=$BUILD_BENCHMARKS

# Set to \`Debug\` to compile in debug symbols during \`make rapids\` target
CMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE

# Set which GPU the containers should see when running tests/notebooks
NVIDIA_VISIBLE_DEVICES=$NVIDIA_VISIBLE_DEVICES
"
}

if [ ! -f "$PWD/compose/.env" ]; then
    compose_env_file > "$PWD/compose/.env"
fi

CHANGED="$(diff -qwB "$PWD/compose/.env" <(compose_env_file) || true)"

if [ -n "${CHANGED// }" ]; then
    echo "Difference between current .env and proposed .env:";
    diff -wBy --suppress-common-lines "$PWD/compose/.env" <(compose_env_file) || true;
    while true; do
        read -p "Do you wish to overwrite your current compose/.env file? (y/n) " yn </dev/tty
        case $yn in
            [Nn]* ) break;;
            [Yy]* ) compose_env_file > "$PWD/compose/.env"; break;;
            * ) echo "Please answer 'y' or 'n'";;
        esac
    done
fi
