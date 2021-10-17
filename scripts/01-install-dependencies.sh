#!/usr/bin/env bash

set -Eeo pipefail

cd $(dirname "$(realpath "$0")")/../../

APT_DEPS=""
NEEDS_REBOOT=""
INSTALLED_CLANGD=""
INSTALLED_DOCKER=""
INSTALLED_NVIDIA_CONTAINER_RUNTIME=""

sudo_warn() {
    echo "Running '$*' as root."
    sudo "$@"
}

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
    APT_DEPS="${APT_DEPS:+$APT_DEPS }clangd"
    curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key | sudo_warn apt-key add -
    release=$(lsb_release -cs)
    echo "deb http://apt.llvm.org/$release/ llvm-toolchain-$release-13 main
deb-src http://apt.llvm.org/$release/ llvm-toolchain-$release-13 main
" | sudo_warn tee /etc/apt/sources.list.d/llvm.list
}

install_vscode() {
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo_warn install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/ && rm packages.microsoft.gpg
    sudo_warn sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    APT_DEPS="${APT_DEPS:+$APT_DEPS }code"
}

install_docker() {
    NEEDS_REBOOT=1
    INSTALLED_DOCKER=1
    APT_DEPS="${APT_DEPS:+$APT_DEPS }docker-ce"
    release=$(lsb_release -cs)
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo_warn apt-key add -
    sudo_warn add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $release stable"
}

install_docker_compose() {
    DOCKER_COMPOSE_VERSION="1.29.2"
    sudo_warn curl \
        -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose && sudo_warn chmod +x /usr/local/bin/docker-compose
}

install_nvidia_container_toolkit() {
    INSTALLED_NVIDIA_CONTAINER_RUNTIME=1
    APT_DEPS="${APT_DEPS:+$APT_DEPS }nvidia-container-toolkit nvidia-container-runtime"
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo_warn apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo_warn tee /etc/apt/sources.list.d/nvidia-docker.list
}

# Install curl if not installed
if [ -z "$(which curl)" ]; then
    APT_DEPS="${APT_DEPS:+$APT_DEPS }curl libssl-dev libcurl4-openssl-dev"
fi
# Install wget if not installed
if [ -z "$(which wget)" ]; then
    APT_DEPS="${APT_DEPS:+$APT_DEPS }wget"
fi
# Install make if not installed
if [ -z "$(which make)" ]; then
    APT_DEPS="${APT_DEPS:+$APT_DEPS }make"
fi
# Install jq if not installed
if [ -z "$(which jq)" ]; then
    APT_DEPS="${APT_DEPS:+$APT_DEPS }jq"
fi

if [ -n "$APT_DEPS" ]; then
    sudo_warn apt update || true
    sudo_warn apt install -y $APT_DEPS
    APT_DEPS=""
fi;

# Install clangd if not installed
if [ -z "$(which clangd)" ]; then
    ask_before_install "clangd not found. Install clangd (y/n)?" "install_clangd"
fi

# Install vscode if not installed
if [ -z "$(which code)" ]; then
    # Only prompt to install vscode if vscode-insiders isn't installed either
    if [ -z "$(which code-insiders)" ]; then
        ask_before_install "VSCode not found. Install VSCode (y/n)?" "install_vscode"
    fi
fi

# Install docker-ce if not installed
if [ -z "$(which docker)" ]; then
    ask_before_install "docker not found. Install docker (y/n)?" "install_docker"
fi

# Install docker-compose if not installed
if [ -z "$(which docker-compose)" ]; then
    ask_before_install "docker-compose not found. Install docker-compose (y/n)?" "install_docker_compose"
fi

# Install nvidia-container-toolkit if not installed
if [ ! -f "/etc/apt/sources.list.d/nvidia-docker.list" ]; then
    ask_before_install "nvidia-container-toolkit not found. Install nvidia-container-toolkit (y/n)?" "install_nvidia_container_toolkit"
elif [ -n "$(apt policy nvidia-container-toolkit 2> /dev/null | grep -i 'Installed: (none)')" ]; then
    ask_before_install "nvidia-container-toolkit not found. Install nvidia-container-toolkit (y/n)?" "install_nvidia_container_toolkit"
fi

if [ -n "$APT_DEPS" ]; then

    echo "installing $APT_DEPS"
    sudo_warn apt update || true
    sudo_warn apt install -y $APT_DEPS

    if [ -n "$INSTALLED_DOCKER" ]; then
        sudo_warn usermod -aG docker $USER
    fi
fi

export NEEDS_REBOOT;
