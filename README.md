
# Rapids docker-compose environment

```bash
$ cd ~/dev/rapids
$ git clone ssh://git@gitlab-master.nvidia.com:12051/pataylor/rapids-compose.git compose
```

### Quick links
* [Prerequisites](#prerequisites)
* [Fork or clone the repos](#fork-or-clone-these-repos)
* [Create and edit config files for your environment](#create-and-edit-the-config-files-for-your-local-dev-environment)
* [Build the containers](#build-the-containers)
* [Run the containers with your file system mounted in](#run-the-containers-with-your-file-system-mounted-in)
* [Run cudf pytests](#run-cudf-pytests)
* [Launch the containers with your file system mounted in](#launch-a-notebook-container-with-your-file-system-mounted-in)
* [Debug Python running in the container with VSCode](#debug-python-running-in-the-container-with-vscode)

## Prerequisites
* [`docker-compose`](https://github.com/docker/compose/releases)

    Quick install:
    ```bash
    $ sudo curl -L https://github.com/docker/compose/releases/download/1.25.0-rc1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
    $ sudo chmod +x /usr/local/bin/docker-compose
    ```
* [`jq`](https://stedolan.github.io/jq/)

    Quick install:
    ```
    $ sudo apt install jq
    ```

## Fork or clone these repos

* [rapidsai/rmm](http://github.com/rapidsai/rmm)
* [rapidsai/cudf](http://github.com/rapidsai/cudf)
* [rapidsai/cugraph](http://github.com/rapidsai/cugraph)
* [rapidsai/custrings](http://github.com/rapidsai/custrings)
* [rapidsai/notebooks](http://github.com/rapidsai/notebooks)
* [rapidsai/notebooks-extended](http://github.com/rapidsai/notebooks-extended)

Then check out your forks locally:

```bash
$ mkdir -p ~/dev/rapids && cd ~/dev/rapids
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
EOF
```

## Create and edit the config files for your local dev environment
```bash
# Set any container environment variables in the .env file
$ cp .env.example > .env
# Configure the paths where your local copies of RAPIDS repos live
$ cp .localpaths.example > .localpaths
$ gedit .localpaths
```

## Build the containers (only builds stages that have been invalidated)

```bash
# Builds base containers, compiles rapids projects, builds notebook containers
$ make
# Builds base containers and compiles rapids projects
$ make rapids
# Builds notebook containers
$ make notebooks
```

## Run the containers with your file system mounted in

```bash
# args is appended to the end of: `docker-compose run --rm rapids $args`
$ make rapids.run args="bash"
root@xxx:/# echo "No not in the ocean -- *inside* the ocean."
root@xxx:/# cd /opt/rapids/cudf && py.test -v -x -k test_my_feature
root@xxx:/# exit
###
# Or the long way, expands out to: `docker-compose $cmd $svc $args`
###
$ make dc cmd="run" svc="rapids" args="bash"
```

## Run cudf pytests (and optionally apply a test filter expression)
```sh
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

Install the [VSCode Python Debugger](https://github.com/Microsoft/ptvsd)

Create a `.vscode/launch.json` [debug configuration](https://code.visualstudio.com/docs/python/debugging). It should look something like this:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Remote Attach",
            "type": "python",
            "request": "attach",
            "port": 5678,
            "host": "172.18.0.2",
            "pathMappings": [
                {
                    "localRoot": "${workspaceFolder}",
                    "remoteRoot": "/opt/rapids"
                }
            ]
        }
    ]
}

```

Then launch the unit tests (with an optional pytest expression filter):

```sh
$ make rapids.cudf.test.debug expr="test_reindex_dataframe"
# ...
make[1]: Leaving directory '/home/ptaylor/dev/rapids/compose'
"Debugger listening at: 172.18.0.2"
$ 
```

Ensure the IP address printed on the last line matches the `"host"` entry in `.vscode/launch.json`.

If it doesn't, update launch.json with the IP address printed in the terminal.

Set breakpoints in the python code and hit the green `Start Debugging` button in VSCode.

