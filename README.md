
# Rapids docker-compose environment

### Quick links
* [Prerequisites](#prerequisites)
* [Installation and Usage](#installation-and-usage)

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

## Installation and Usage

```shell
# 1. Create a directory for all the rapids projects to live
$ mkdir -p ~/dev/rapids && cd ~/dev/rapids

# 2. Check out the rapids-compose repo into ./compose
$ git clone ssh://git@gitlab-master.nvidia.com:12051/pataylor/rapids-compose.git compose \
  && cd compose

# 3. Check out the rapids repos and setup VSCode Python and C++ intellisense
$ make init

# 4. Build the rapids and notebook containers
#   a. Only build the rapids container: `make rapids`
#   b. Only build the notebook container: `make notebooks`
$ make

# 5. Launch the notebook container
$ make notebooks.run

# 6. Run cudf pytests (accepts any valid pytest args)
#   a. Run pytests in parallel with pytest-xdist, pass `args="-n auto"`
$ make rapids.cudf.pytest args="-k 'test_string_index'"

# 7. Debug pytests running in the container (accepts any valid pytest args)
#   a. This launches pytest with `ptvsd` for debugging in VSCode
$ make rapids.cudf.pytest.debug args="-k 'test_reindex_dataframe'"

# 8. Run the rapids container and launch a tty to explore the container
$ make rapids.run args="bash"
```
