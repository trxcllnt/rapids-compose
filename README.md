
# Rapids docker-compose environment

### Quick links
* [Prerequisites](#prerequisites)
* [Clone and set up local compose environment](#clone-and-set-up-local-compose-environment)
* [Fork and clone the Rapids projects](#fork-and-clone-the-rapids-projects)
* [Setup VSCode for C++ and Python development](#setup-vscode-for-c-and-python-development)
* [Build the containers](#build-the-containers-only-builds-stages-that-have-been-invalidated)
* [Run the containers with your file system mounted in](#run-the-containers-with-your-file-system-mounted-in)
* [Run cudf pytests](#run-cudf-pytests-and-optionally-apply-a-test-filter-expression)
* [Launch a notebook container with your file system mounted in](#launch-a-notebook-container-with-your-file-system-mounted-in)
* [Debug Python running in the container with VSCode](#debug-python-running-in-the-container-with-vscode)

## Prerequisites
* [`jq`](https://stedolan.github.io/jq/):
    ```
    $ sudo apt install jq
    ```
* [`docker-compose`](https://github.com/docker/compose/releases)
    ```bash
    $ sudo curl \
    -L https://github.com/docker/compose/releases/download/1.24.1/docker-compose-`uname -s`-`uname -m` \
    -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose
    ```

## Clone and set up local compose environment

```bash
# Create a directory for all the Rapids projects to live
$ mkdir -p ~/dev/rapids && cd ~/dev/rapids

# Check out the rapids-compose repo into $PWD/compose
$ git clone ssh://git@gitlab-master.nvidia.com:12051/pataylor/rapids-compose.git "$PWD/compose"

# Create a file to customize container build args/env vars
$ cat << EOF > "$PWD/compose/.env"
# Build arguments
RAPIDS_HOME=$PWD
CUDA_VERSION=10.0
PYTHON_VERSION=3.7
LINUX_VERSION=ubuntu18.04

# Whether to build C++/cuda tests during \`make rapids\` target
BUILD_TESTS=on

# Set to \`Debug\` to compile in debug symbols during \`make rapids\` target
CMAKE_BUILD_TYPE=Release

# Set which GPU the containers should see when running tests/notebooks
NVIDIA_VISIBLE_DEVICES=0
EOF

# Create VScode workspaces for the projects (optional)
$ cat << EOF > "$PWD/rapids.code-workspace"
{
    "folders": [
        {"name": "compose", "path": "compose"},
        {"name": "cudf-cpp", "path": "cudf/cpp"},
        {"name": "cudf-python", "path": "cudf/python/cudf"},
        {"name": "cugraph-cpp", "path": "cugraph/cpp"},
        {"name": "cugraph-python", "path": "cugraph/python"},
        {"name": "custrings-cpp", "path": "custrings/cpp"},
        {"name": "custrings-python", "path": "custrings/python"},
        {"name": "rmm-cpp", "path": "rmm"},
        {"name": "notebooks", "path": "notebooks"},
        {"name": "notebooks-extended", "path": "notebooks-extended" }
    ]
}
EOF

```

## Fork and clone the Rapids projects

* [rapidsai/rmm](http://github.com/rapidsai/rmm)
* [rapidsai/cudf](http://github.com/rapidsai/cudf)
* [rapidsai/cugraph](http://github.com/rapidsai/cugraph)
* [rapidsai/custrings](http://github.com/rapidsai/custrings)
* [rapidsai/notebooks](http://github.com/rapidsai/notebooks)
* [rapidsai/notebooks-extended](http://github.com/rapidsai/notebooks-extended)

Then check out your forks locally:

```bash
$ cd ~/dev/rapids

# Be sure to replace `GITHUB_USER` with your github username here
$ GITHUB_USER="rapidsai" bash << "EOF"
REPOS="rmm cudf cugraph custrings notebooks notebooks-extended"
for REPO in $REPOS
do
    git clone git@github.com:$GITHUB_USER/$REPO.git
    cd $REPO
    git submodule update --init --remote --recursive
    git remote add -f upstream git@github.com:rapidsai/$REPO.git
    cd -
done
mkdir -p "$PWD/compose/etc/include"
ln -s "$PWD/cugraph/cpp/include" "$PWD/compose/etc/include/cugraph"
ln -s "$PWD/custrings/cpp/include" "$PWD/compose/etc/include/nvstrings"
EOF

```

## Setup VSCode for C++ and Python development

Install these extensions:
 * [C/C++](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools)
 * [CMake](https://marketplace.visualstudio.com/items?itemName=twxs.cmake)
 * [Python](https://marketplace.visualstudio.com/items?itemName=ms-python.python)
 * [Language-Cython](https://marketplace.visualstudio.com/items?itemName=guyskk.language-cython)

Now configure VSCode C++ intellisense:

```bash
$ cd ~/dev/rapids

# Create VSCode C++ configurations
$ mkdir -p "$PWD/rmm/.vscode"

cat << EOF > "$PWD/rmm/.vscode/c_cpp_properties.json"
{
    "configurations": [
        {
            "name": "Linux",
            "includePath": [
                "\${workspaceFolder}/**",
                "/usr/local/cuda/lib64",
                "/usr/local/cuda/include",
                "/usr/local/cuda/nvvm/lib64",
                "$PWD/rmm/include",
                "$PWD/cudf/cpp/include",
                "$PWD/compose/etc/include"
            ],
            "defines": [],
            "compilerPath": "/usr/bin/gcc",
            "cStandard": "c11",
            "cppStandard": "c++17",
            "intelliSenseMode": "\${default}"
        }
    ],
    "version": 4
}
EOF

cp -r "$PWD/rmm/.vscode" "$PWD/cudf/"
cp -r "$PWD/rmm/.vscode" "$PWD/cugraph/"
cp -r "$PWD/rmm/.vscode" "$PWD/custrings/"

```

## Build the containers (only builds stages that have been invalidated)

```bash
$ cd ~/dev/rapids/compose
# Builds base containers, compiles rapids projects, builds notebook containers
$ make
# Builds base containers and compiles rapids projects
$ make rapids
# Builds notebook containers
$ make notebooks
```

## Run the containers with your file system mounted in

```bash
$ cd ~/dev/rapids/compose
# args is appended to the end of: `docker-compose run --rm rapids $args`
$ make rapids.run args="bash"
root@xxx:/rapids# echo "No not in the ocean -- *inside* the ocean."
root@xxx:/rapids# cd cudf && py.test -v -x -k test_my_feature
root@xxx:/rapids# exit
###
# Or the long way, expands out to: `docker-compose $cmd $svc $args`
###
$ make dc cmd="run" svc="rapids" args="bash"
```

## Run cudf pytests (and optionally apply a test filter expression)
```sh
$ cd ~/dev/rapids/compose
$ make rapids.cudf.test expr="test_string_index"
# ...
============================================================ test session starts =============================================================
# ...
collected 11735 items / 11733 deselected / 2 skipped                                                                                         
python/cudf/tests/test_multiindex.py::test_string_index PASSED                                                                         [ 50%]
python/cudf/tests/test_string.py::test_string_index PASSED                                                                             [100%]
===================================== 2 passed, 2 skipped, 11733 deselected, 1 warnings in 3.09 seconds ======================================
```

## Launch a notebook container with your file system mounted in
```bash
$ cd ~/dev/rapids/compose
$ make notebooks.up
> Creating compose_notebooks_1 ... done
# Monitor the jupyterlab stdout/err logs
$ make notebooks.logs
> Attaching to compose_notebooks_1
> notebooks_1  | [I 10:13:25.192 LabApp] Writing notebook server cookie secret to /home/rapids/.local/share/jupyter/runtime/notebook_cookie_secret
> notebooks_1  | [W 10:13:25.336 LabApp] All authentication is disabled.  Anyone who can connect to this server will be able to run code.
> notebooks_1  | [I 10:13:25.343 LabApp] JupyterLab extension loaded from /usr/local/lib/python3.7/dist-packages/jupyterlab
> ...^C
# Shut down the notebooks container and local compose_default network
$ docker-compose down
> Stopping compose_notebooks_1 ... done
> Removing compose_notebooks_1 ... done
> Removing network compose_default
```

## Debug Python running in the container with VSCode

Create a VSCode Python Debugger [launch configuration](https://code.visualstudio.com/docs/python/debugging):
```bash
$ cd ~/dev/rapids
$ cat << EOF > "$PWD/cudf/python/cudf/.vscode/launch.json"
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug Python",
            "type": "python",
            "request": "attach",
            "port": 5678,
            "host": "172.18.0.2",
            "pathMappings": [
                {
                    "localRoot": "\${workspaceFolder}",
                    "remoteRoot": "\${workspaceFolder}"
                }
            ]
        }
    ]
}
EOF
```

Launch the unit tests in the container (with an optional pytest expression filter):

```bash
$ cd ~/dev/rapids/compose
$ make rapids.cudf.test.debug expr="test_reindex_dataframe"
"Debugger listening at: 172.18.0.2"
```

Ensure the IP address printed on the last line matches the `"host"` entry in `.vscode/launch.json`.

If it doesn't, update launch.json with the IP address printed in the terminal.

Set breakpoints in the python code and hit the green `Start Debugging` button in VSCode.

