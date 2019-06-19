
# Rapids docker-compose environment

```bash
$ cd ~/dev/rapids
$ git clone ssh://git@gitlab-master.nvidia.com:12051/pataylor/rapids-compose.git compose
```

### Quick links
* [Fork or clone the repos](#fork-or-clone-these-repos)
* [Create and edit config files for your environment](#create-and-edit-the-config-files-for-your-local-dev-environment)
* [Build the containers](#build-the-containers)
* [Run the containers with your file system mounted in](#run-the-containers-with-your-file-system-mounted-in)
* [Launch the containers with your file system mounted in](#launch-a-notebook-container-with-your-file-system-mounted-in)
* [Debug Python running in the container with VSCode](#debug-python-running-in-the-container-with-vscode)

## Fork or clone these repos
```bash
$ mkdir ~/dev/rapids && cd ~/dev/rapids
$ git clone git@github.com:rapidsai/build.git
$ git clone git@github.com:rapidsai/cudf.git
$ git clone git@github.com:rapidsai/cugraph.git
$ git clone git@github.com:rapidsai/custrings.git
$ git clone git@github.com:rapidsai/notebooks.git
$ git clone git@github.com:rapidsai/notebooks-extended.git
$ git clone git@github.com:rapidsai/rmm.git
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
$ make base
# This will build base first
$ make rapids
# This will build base and rapids first
$ make notebooks
```

## Run the containers with your file system mounted in

```bash
$ make run svc="rapids" svc_args="bash"
root@xxx:/# echo "No not in the ocean -- *inside* the ocean."
root@xxx:/# cd /opt/rapids/cudf && py.test -v -x -k test_my_feature
root@xxx:/# exit
# Or a shortcut:
$ make rapids.run args="bash"
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
$ make debug.cudf expr="test_reindex_dataframe"
# ...
make[1]: Leaving directory '/rapids/compose'
"Debugger listening at: 172.18.0.2"
$ 
```

Ensure the IP address printed on the last line matches the `"host"` entry in `.vscode/launch.json`.

If it doesn't, update launch.json with the IP address printed in the terminal.

Set breakpoints in the python code and hit the green `Start Debugging` button in VSCode.

