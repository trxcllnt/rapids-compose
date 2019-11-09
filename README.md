
# Rapids docker-compose environment for Ubuntu 18.04.3

### Quick links
* [Installation](#installation)
* [Usage](#usage)

## Installation
```shell
# 1. Create a directory for all the Rapids workspace (any directory is OK)
$ mkdir -p ~/dev/rapids && cd ~/dev/rapids

# 2. Check out the rapids-compose repo into ./compose
$ git clone ssh://git@gitlab-master.nvidia.com:12051/pataylor/rapids-compose.git compose \
  && cd compose

# 3. Initialize the local compose environment:
#   a. Install dependencies
#   b. Fork and/or clone the Rapids repositories
#   c. Setup VSCode's C++ and Python intellisense
$ make init
```

## Usage

```shell
# 1. Build the rapids dev and notebook containers
#   a. Only build the rapids container: `make rapids`
#   b. Only build the notebook container: `make notebooks`
$ make

# 2. Launch the notebook container
$ make notebooks.run

# 3. Run cudf pytests (accepts any valid pytest args)
#   a. Run pytests in parallel with pytest-xdist, pass `args="-n auto"`
$ make rapids.cudf.pytest args="-k 'test_string_index'"

# 4. Debug pytests running in the container (accepts any valid pytest args)
#   a. This launches pytest with `ptvsd` for debugging in VSCode
$ make rapids.cudf.pytest.debug args="-k 'test_reindex_dataframe'"

# 5. Run the rapids container and launch a tty to explore the container
$ make rapids.run args="bash"
```
