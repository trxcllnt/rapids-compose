
# RAPIDS docker-compose environment for Ubuntu 16.04/18.04

## Quick links
* [Synopsis](#synopsis)
* [Installation](#installation)
  * [Updating](#updating)
* [Usage](#usage)
* [Troubleshooting](#miscellaneous-troubleshooting)
* [Wishlist](#wishlist)

## Synopsis

This is a collection of scripts for setting up an environment for RAPIDS
development and notebooks starting from a clean install of Ubuntu 16.04
or 18.04. It automates the following steps:

1. Installation of dependencies:
   - [Clangd](https://clang.llvm.org/extra/clangd/) - a language server used to
     add smart features to an IDE, e.g. VSCode.
   - [Visual Studio Code](https://code.visualstudio.com/) - an IDE.
   - [Docker](https://www.docker.com/resources/what-container) - A container
     technology for packaging up code with all its dependencies.
   - [`docker-compose`](https://docs.docker.com/compose/) - A tool for building,
     configuring, and running groups of docker containers
   - [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker) - For
     building GPU-accelerated docker containers.
2. Creation of a `docker-compose` environment:
   - Contains suitable settings of compiler and Python versions and other build
     parameters.
3. Creation of a VSCode workspace:
   - Sets up syntax highlighting, intellisense for C++, CUDA and Python
   - Set up some Git conveniences.
4. Forking and cloning of the RAPIDS repositories:
   - [RAPIDS Memory Manager](https://github.com/rapidsai/rmm)
   - [cuDF](https://github.com/rapidsai/cudf)
   - [cuGraph](https://github.com/rapidsai/cugraph)
   - [RAPIDS Sample Notebooks](https://github.com/rapidsai/notebooks)
   - [RAPIDS Community Notebooks](https://github.com/rapidsai/notebooks-contrib)
5. Creation of containers for development work:
   - `dind`: The Docker-in-Docker container. This container is built first to
     provide a clean environment for running `docker-compose` in to build the
     other containers. This allows us to mount your local filesystem as docker
     volumes while selectively ignoring folders that bloat the docker build
     cache and slow down container builds.
   - `rapids`: Contains builds of all the RAPIDS repositories listed above and
     tooling to support development with Visual Studio Code.
   - `notebooks`: Serves Jupyter notebooks using the RAPIDS libraries built by
     the `rapids` container. This allows you to easily test out new features or
     fixes to C++ or Python in any of our example demo notebooks.


## Installation

Starting with the assumption that this repository has not yet been cloned, and
no other dependencies are installed, these steps:

- Install all dependencies,
- Fork and clone the RAPIDS repositories,
- Set up the VSCode environment and Intellisense.

During execution, you will be asked if you would like to install various
dependencies - it is generally a sensible and safe to answer "yes" to these
questions.

For the forking of Github repositories, you will also be asked for Github login
details so that the script can use the Github CLI to fork from the RAPIDS Github
account to your account.

```shell
# 1. Create a directory for all the RAPIDS workspace (any directory is OK)
mkdir -p ~/dev/rapids && cd ~/dev/rapids

# 2. Install Makefile and script dependencies:
sudo apt install curl jq make

# 3. Check out the rapids-compose repo into ./compose
git clone https://github.com/trxcllnt/rapids-compose.git compose
cd compose

# 4. Initialize the local compose environment:
make init
```

You will be asked to reboot if `make init` installed `docker` for you.

### Updating

This is a living repo and will evolve along with the RAPIDS projects. It's a good
idea to periodically pull the latest version of the repository to ensure your dev
workflow is kept up-to-date with any changes to the RAPIDS projects' environments:

`make init` is idempotent, so it's safe to run it from scratch as many times as
necessary. It will ask permission before installing any programs or modifying
any local files, so don't worry about losing any local modifications to your
VSCode workspace or `.env` files.

```shell
# `cd` to the directory where you checked out this repo
cd ~/dev/rapids/compose
# pull the latest changes
git pull origin master
# re-run `make init` to ensure any new settings are applied
make init
```


## Usage

### Building the containers

To build the dev and notebook containers:

```shell
# 1. Build the RAPIDS dev and notebook containers
#   a. Only build the rapids container: `make rapids`
#   b. Only build the notebook container: `make notebooks`
make
```

This only needs to be done once to create the containers. During normal
development, RAPIDS components can be rebuilt inside the dev container.

`make` is the "easy button" to build the containers and compile each of
the RAPIDS projects from source.

If you want to rebuild your containers (e.g. after a `docker pull nvidia/cuda`,
or modifing the container `Dockerfiles`), or if you want to take a coffee break
and come back to a fully re-built set of RAPIDS projects, it's always safe to
`docker rm -f` any existing rapids containers and re-run `make` from top.


### Launching the Notebook container

To launch the notebook container (needed each time the system is started):

```shell
make notebooks.run
```


### Running tests

To run the cuDF pytests, use the `rapids.cudf.pytest` target, which accepts any valid
pytest args. E.g.:

```shell
make rapids.cudf.pytest args="-k 'test_string_index'"
```

To run pytests in parallel with pytest-xdist, pass `args="-n auto"`.


### Debugging tests

To debug tests running in the container, use the `rapids.cudf.pytest.debug`:

```shell
make rapids.cudf.pytest.debug args="-k 'test_reindex_dataframe'"
```

This launches pytest with `debugpy` for debugging in VSCode.


### Working interactively in the RAPIDS container

To run the rapids container and launch a tty to explore it interactively, run:

```shell
make rapids.run args="bash"
```


## Miscellaneous Troubleshooting

### Conda environment conflicts

"I changed something in my .env, restarted the container and now conda is spending hours resolving
conflicts. What do I do?"

`rapids-compose` builds a combined conda environment from the environments of all the RAPIDS
repos (cuDF, cuML, cuGraph, RMM, etc.). So if one of those repos on your system is out of sync, 
there can be conflicts. To solve this:

 * ensure you have all repos pulled to the same branch. If you are working on a feature branch,
   you may need to merge the latest from the base branch into your feature branch.
 * `compose/scripts/git-checkout-same-branch.sh` is a script that automates checking out all of your
   repos to the same branch. It examines the repos and prompts with a choice of common branches.
 * If you are using a CUDA toolkit release candidate or prerelease (e.g. CUDA 11.0 RC), there may
   not be conda packages for this available yet. In this case, you can still build RAPIDS libraries 
   (e.g. libcudf.so) from source, but you may not be able to build and use the Python 
   bindings/libraries. In this situation, in the `compose/.env` file, you need to set `CUDA_VERSION`
   to the version of the CUDA toolkit you want to use, but set `CONDA_CUDA_TOOLKIT_VERSION` to the 
   latest earlier version for which conda packages exist. So in the case of working with CUDA 11.0 
   RC, set

   ```
   CUDA_VERSION=11.0
   CONDA_CUDA_TOOLKIT_VERSION=10.2
   ```
  

### DNS Resolution Issues

When creating the Docker-in-Docker container, downloading of the Alpine package
release key fails with the following error:

```
+ wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
wget: bad address 'alpine-pkgs.sgerrand.com'
```

This is a DNS resolution failure in the container - there can be numerous causes
for DNS resolution failures, but one that can occur within the NVIDIA
environment is the Cisco AnyConnect client breaking networking for containers.
If this occurs, a possible resolution is to restart the machine and attempt
`make init` again prior to making any VPN connections.

Alternatively, you can use the Cisco-compatible OpenConnect VPN client, which
seems to have better integration with `systemd`:
```
sudo apt install network-manager-openconnect-gnome
```

### Error running `groupadd`

When building the RAPIDS container, an error running `groupadd` is encountered
just after the build of `ccache`:

```
...
  INSTALL  ccache
  INSTALL  ccache.1
/
groupadd: GID '0' already exists
```

This occurs if you are running `make init` as root. You should run it under your
normal user account.


## Wishlist

## Acknowledgements
Inspired by container development patterns from @MillerHooks
