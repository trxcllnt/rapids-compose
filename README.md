
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

# Whether to build C++/cuda tests/benchmarks during \`make rapids\` target
BUILD_TESTS=ON
BUILD_BENCHMARKS=OFF

# Set to \`Debug\` to compile in debug symbols during \`make rapids\` target
CMAKE_BUILD_TYPE=Release

# Set which GPU the containers should see when running tests/notebooks
NVIDIA_VISIBLE_DEVICES=0
EOF

# Create a VSCode workspace for the projects (optional)
$ cat << EOF > "$PWD/rapids.code-workspace"
{
    "folders": [
        {"name": "compose", "path": "compose"},
        {"name": "cudf-cpp", "path": "cudf/cpp"},
        {"name": "cudf-java", "path": "cudf/java"},
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
$ cd ~/dev/rapids && bash << "EOF"
read -p "enter your github username: " GITHUB_USER </dev/tty
REPOS="rmm cudf cugraph custrings notebooks notebooks-extended"
for REPO in $REPOS
do
    git clone --recurse-submodules git@github.com:$GITHUB_USER/$REPO.git
    cd $REPO && git remote add -f upstream git@github.com:rapidsai/$REPO.git
    cd -
done
EOF

```

Use this script to fetch and merge changes from upstream:

```bash
$ cd ~/dev/rapids && bash << "EOF"
read -p "enter the upstream branch to pull from: " BRANCH_NAME </dev/tty
REPOS="rmm cudf cugraph custrings"
for REPO in $REPOS
do
    cd $REPO
    DIRTY="$(git status -s)"
    [ -n "${DIRTY// }" ] && git stash -u
    git fetch upstream && git checkout "$BRANCH_NAME"
    git pull --recurse-submodules upstream "$BRANCH_NAME"
    [ -n "${DIRTY// }" ] && git stash pop
    cd -
done
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

# Create a directory to hold symlinks to the include dirs so the source paths match the include paths
$ mkdir -p "$PWD/compose/etc/rapids/include"
ln -f -n -s "$PWD/cugraph/cpp/include" "$PWD/compose/etc/rapids/include/cugraph"
ln -f -n -s "$PWD/custrings/cpp/include" "$PWD/compose/etc/rapids/include/nvstrings"
ln -f -n -s "$PWD/cudf/cpp/build/compile_commands.json" "$PWD/cudf/cpp/compile_commands.json"
ln -f -n -s "$PWD/cudf/java/src/main/native/include/jni_utils.hpp" "$PWD/compose/etc/rapids/include/jni_utils.hpp"

# Create the VSCode C++ intellisense configuration in compose/etc/rapids/.vscode
# Symlink that directory into each rapids project.
$ mkdir -p \
    "$PWD/cugraph/python/.vscode" \
    "$PWD/custrings/python/.vscode" \
    "$PWD/cudf/python/cudf/.vscode" \
    "$PWD/cudf/python/dask_cudf/.vscode"

cat << EOF > "$PWD/compose/etc/rapids/.vscode/c_cpp_properties.json"
{
    "configurations": [
        {
            "name": "Linux",
            "includePath": [
                "\${workspaceFolder}/**",
                "/usr/local/cuda/include",
                "$PWD/rmm/include",
                "$PWD/cudf/cpp/include",
                "$PWD/custrings/cpp/include",
                "$PWD/compose/etc/rapids/include"
            ],
            "browse": {
                "limitSymbolsToIncludedHeaders": true,
                "path": [
                    "\${workspaceFolder}",
                    "/usr/local/cuda/include",
                    "$PWD"
                ]
            },
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

ln -f -n -s "$PWD/compose/etc/rapids/.vscode" "$PWD/rmm/.vscode"
ln -f -n -s "$PWD/compose/etc/rapids/.vscode" "$PWD/cudf/.vscode"
ln -f -n -s "$PWD/compose/etc/rapids/.vscode" "$PWD/cugraph/.vscode"
ln -f -n -s "$PWD/compose/etc/rapids/.vscode" "$PWD/custrings/.vscode"
ln -f -n -s "$PWD/compose/etc/rapids/.vscode" "$PWD/cudf/cpp/.vscode"
ln -f -n -s "$PWD/compose/etc/rapids/.vscode" "$PWD/cudf/java/.vscode"
ln -f -n -s "$PWD/compose/etc/rapids/.vscode" "$PWD/cugraph/cpp/.vscode"
ln -f -n -s "$PWD/compose/etc/rapids/.vscode" "$PWD/custrings/cpp/.vscode"
ln -f -n -s "$PWD/compose/etc/rapids/.vscode" "$PWD/custrings/python/.vscode"

```

Now create workspace-specific settings. Feel free to copy these to your global `settings.json` file if you find them useful:

```bash
$ cat << EOF > "$PWD/compose/etc/rapids/.vscode/settings.json"
{
    "search.exclude": {
        "**/build/include": true
    },
    "files.associations": {
        "*.cu": "cpp",
        "*.cuh": "cpp"
    },
    "files.exclude": {
        "**/.git": true,
        "**/.svn": true,
        "**/.hg": true,
        "**/CVS": true,
        "**/.DS_Store": true,
        "**/*.egg": true,
        "**/*.egg-info": true,
        "**/__pycache__": true,
        "**/.pytest_cache": true,
        "**/build/include": true,
        "**/cudf/_lib/**/*.so": true,
        "**/cudf/_lib/**/*.cpp": true,
        "**/build/lib.linux-x86_64*": true,
        "**/build/temp.linux-x86_64*": true,
        "**/build/bdist.linux-x86_64*": true,
    },
    "C_Cpp.exclusionPolicy": "checkFolders",
    "C_Cpp.intelliSenseCachePath": "$PWD/compose/etc/rapids/.vscode/.vscode-cpptools"
}
EOF

ln -f -s "$PWD/compose/etc/rapids/.vscode/settings.json" "$PWD/cugraph/python/.vscode/settings.json"
ln -f -s "$PWD/compose/etc/rapids/.vscode/settings.json" "$PWD/cudf/python/cudf/.vscode/settings.json"
ln -f -s "$PWD/compose/etc/rapids/.vscode/settings.json" "$PWD/cudf/python/dask_cudf/.vscode/settings.json"

```

## Build the containers (only builds stages that have been invalidated)

```bash
$ cd ~/dev/rapids/compose
# Builds containers, compiles rapids projects, builds notebook containers
$ make
# Builds containers and compiles rapids projects
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

