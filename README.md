
# Rapids docker-compose environment

### Quick links
* [Prerequisites](#prerequisites)
* [Clone and create local rapids dev compose environment](#clone-and-create-local-rapids-dev-compose-environment)
* [Build the containers](#build-the-containers-only-builds-stages-that-have-been-invalidated)
* [Run the containers with your file system mounted in](#run-the-containers-with-your-file-system-mounted-in)
* [Run cudf pytests](#run-cudf-pytests-and-optionally-apply-a-test-filter-expression)
* [Launch a notebook container with your file system mounted in](#launch-a-notebook-container-with-your-file-system-mounted-in)
* [Debug Python running in the container with VSCode](#debug-python-running-in-the-container-with-vscode)

## Prerequisites
* ### [VSCode](https://code.visualstudio.com/docs/setup/linux)
    ```shell
    $ curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
      && sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/ && rm packages.microsoft.gpg \
      && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" \
       | sudo tee /etc/apt/sources.list.d/vscode.list \
      && sudo apt update && sudo apt install -y code
    ```
* ### [`clangd`](https://clang.llvm.org/extra/clangd/Installation.html)
    ```shell
    $ sudo apt install -y clang-tools-8 \
      && sudo update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-8 100
    ```
* ### [`docker-compose`](https://github.com/docker/compose/releases)
    ```shell
    $ sudo curl \
      -L https://github.com/docker/compose/releases/download/1.24.1/docker-compose-`uname -s`-`uname -m` \
      -o /usr/local/bin/docker-compose \
      && sudo chmod +x /usr/local/bin/docker-compose
    ```

## Clone and create local rapids dev compose environment

```shell
# 1. Create a directory for all the Rapids projects to live
# 2. Check out the rapids-compose repo into $PWD/compose
# 3. Check out the rapids repos and setup intellisense
# 4. Build the rapids and notebook containers
$ mkdir -p ~/dev/rapids && cd ~/dev/rapids \
 && git clone ssh://git@gitlab-master.nvidia.com:12051/pataylor/rapids-compose.git compose && cd compose \
 && bash ./setup.sh \
 && make
```

## Build the containers (only builds stages that have been invalidated)

```shell
$ cd ~/dev/rapids/compose
# Builds containers, compiles rapids projects, builds notebook containers
$ make
# Builds containers and compiles rapids projects
$ make rapids
# Builds notebook containers
$ make notebooks
```

## Run the containers with your file system mounted in

```shell
$ cd ~/dev/rapids/compose
# args is appended to the end of: `docker-compose run --rm rapids $args`
$ make rapids.run args="bash"
rapids@xx:/rapids# echo "No not in the ocean -- *inside* the ocean."
rapids@xx:/rapids# cd cudf && py.test -v -x -k test_my_feature
rapids@xx:/rapids# exit
```

## Run cudf pytests
```sh
$ cd ~/dev/rapids/compose
$ make rapids.cudf.test args="-k 'test_string_index'"
# ...
============================================================ test session starts =============================================================
# ...
collected 11735 items / 11733 deselected / 2 skipped                                                                                         
python/cudf/tests/test_multiindex.py::test_string_index PASSED                                                                         [ 50%]
python/cudf/tests/test_string.py::test_string_index PASSED                                                                             [100%]
===================================== 2 passed, 2 skipped, 11733 deselected, 1 warnings in 3.09 seconds ======================================
```

## Launch a notebook container with your file system mounted in
```shell
$ cd ~/dev/rapids/compose
$ make notebooks.run
> Creating compose_notebooks_1 ... done
> notebooks_1  | [I 10:13:25.192 LabApp] Writing notebook server cookie secret to /home/rapids/.local/share/jupyter/runtime/notebook_cookie_secret
> notebooks_1  | [W 10:13:25.336 LabApp] All authentication is disabled.  Anyone who can connect to this server will be able to run code.
> notebooks_1  | [I 10:13:25.343 LabApp] JupyterLab extension loaded from /usr/local/lib/python3.7/dist-packages/jupyterlab
> ...^C
> Stopping compose_notebooks_1 ... done
> Removing compose_notebooks_1 ... done
> Removing network compose_default
```

## Debug Python running in the container with VSCode

Launch the unit tests in the container (with an optional pytest expression filter):

```shell
$ cd ~/dev/rapids/compose
$ make rapids.cudf.test.debug args="-k 'test_reindex_dataframe'"
```

Set breakpoints in the python code and hit the green `Start Debugging` button in VSCode.
