
# Rapids docker-compose environment for Ubuntu 18.04.3

## Quick links
* [Synopsis](#synopsis)
* [Installation](#installation)
* [Usage](#usage)

## Synopsis

This is a collection of scripts for setting up an environment for RAPIDS
development and notebooks starting from a clean install of Ubuntu 18.04. It
automates the following steps:

1. Installation of dependencies:
   - [Clangd](https://clang.llvm.org/extra/clangd/) - a language server used to
     add smart features to an IDE, e.g. VSCode.
   - [Visual Studio Code](https://code.visualstudio.com/) - an IDE.
   - [Docker](https://www.docker.com/resources/what-container) - A container
     technology for packaging up code with all its dependencies.
   - [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker) - For
     building GPU-accelerated docker containers.
2. Creation of a docker compose environment:
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
     other containers.
   - `rapids`: Contains builds of all the RAPIDS repositories listed above and
     tooling to support development with Visual Studio Code.
   - `notebooks`: For serving notebooks usign RAPIDS libraries using Jupyter.


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
# 1. Create a directory for all the Rapids workspace (any directory is OK)
mkdir -p ~/dev/rapids && cd ~/dev/rapids

# 2. Install Makefile and script dependencies:
sudo apt install curl jq make

# 3. Check out the rapids-compose repo into ./compose
git clone ssh://git@gitlab-master.nvidia.com:12051/pataylor/rapids-compose.git compose \
  && cd compose

# 4. Initialize the local compose environment:
make init
```

You may be asked to reboot after `make init` completes.


## Usage

### Building containers

To build the dev and notebook containers:

```shell
# 1. Build the rapids dev and notebook containers
#   a. Only build the rapids container: `make rapids`
#   b. Only build the notebook container: `make notebooks`
make
```

This only needs to be done once to create the containers. During normal
development, RAPIDS components can be rebuilt inside the dev container.


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

This launches pytest with `ptvsd` for debugging in VSCode.


### Working interactively in the RAPIDS container

To run the rapids container and launch a tty to explore it interactively, run:

```shell
make rapids.run args="bash"
```


## Miscellaneous Troubleshooting

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


