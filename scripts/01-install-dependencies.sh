#!/usr/bin/env bash

set -Eeo pipefail

cd $(dirname "$(realpath "$0")")/../../

APT_DEPS=""
NEEDS_REBOOT=""
INSTALLED_CLANGD=""
INSTALLED_DOCKER=""
INSTALLED_NVIDIA_DOCKER2=""

ask_before_install() {
    while true; do
        read -p "$1 " CHOICE </dev/tty
        case $CHOICE in
            [Nn]* ) break;;
            [Yy]* ) eval $2; break;;
            * ) echo "Please answer 'y' or 'n'";;
        esac
    done
}

install_clangd() {
    INSTALLED_CLANGD=1
    APT_DEPS="${APT_DEPS:+$APT_DEPS }clangd-11"
    curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
    release=$(lsb_release -cs)
    echo "deb http://apt.llvm.org/$release/ llvm-toolchain-$release main
deb-src http://apt.llvm.org/$release/ llvm-toolchain-$release main
" | sudo tee /etc/apt/sources.list.d/llvm.list
}

install_vscode() {
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/ && rm packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    APT_DEPS="${APT_DEPS:+$APT_DEPS }code"
}

install_docker() {
    NEEDS_REBOOT=1
    INSTALLED_DOCKER=1
    APT_DEPS="${APT_DEPS:+$APT_DEPS }docker-ce"
    release=$(lsb_release -cs)
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $release stable"
}

install_docker_compose() {
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r ".tag_name" | tr -d 'v')
    sudo curl \
        -L https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m` \
        -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose
}

install_nvidia_docker_2() {
    INSTALLED_NVIDIA_DOCKER2=1
    APT_DEPS="${APT_DEPS:+$APT_DEPS }nvidia-docker2"
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
}

# Install curl if not installed
if [ -z `which curl` ]; then
    sudo apt update || true && sudo apt install -y curl libssl-dev libcurl4-openssl-dev
fi

# Install jq if not installed
[ -z `which jq` ] && APT_DEPS="${APT_DEPS:+$APT_DEPS }jq"

# Install bear if not installed
[ -z `which bear` ] && APT_DEPS="${APT_DEPS:+$APT_DEPS }bear"

# Install clangd-11 if not installed
if [ -z `which clangd` ]; then
    ask_before_install "clangd not found. Install clangd (y/n)?" "install_clangd"
fi

# Install vscode if not installed
if [ -z `which code` ]; then
    ask_before_install "VSCode not found. Install VSCode (y/n)?" "install_vscode"
fi

# Install docker-ce if not installed
if [ -z `which docker` ]; then
    ask_before_install "docker not found. Install docker (y/n)?" "install_docker"
fi

# Install docker-compose if not installed
if [ -z `which docker-compose` ]; then
    ask_before_install "docker-compose not found. Install docker-compose (y/n)?" "install_docker_compose"
fi

# Install nvidia-docker2 if not installed
if [ ! -f "/etc/apt/sources.list.d/nvidia-docker.list" ]; then
    ask_before_install "nvidia-docker2 not found. Install nvidia-docker2 (y/n)?" "install_nvidia_docker_2"
elif [ -n "$(apt policy nvidia-docker2 2> /dev/null | grep -i 'Installed: (none)')" ]; then
    ask_before_install "nvidia-docker2 not found. Install nvidia-docker2 (y/n)?" "install_nvidia_docker_2"
fi

if [ -n "$APT_DEPS" ]; then

    echo "installing $APT_DEPS"
    sudo apt update || true
    sudo apt install -y $APT_DEPS

    if [ -n "$INSTALLED_CLANGD" ]; then
        sudo update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-11 100
    fi

    if [ -n "$INSTALLED_DOCKER" ]; then
        sudo usermod -aG docker $USER
    fi

    if [ -n "$INSTALLED_NVIDIA_DOCKER2" ]; then
        echo '{
    "default-runtime": "nvidia",
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}' | sudo tee /etc/docker/daemon.json
    fi
fi

export NEEDS_REBOOT
