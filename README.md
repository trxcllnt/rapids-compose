
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

## Build the containers

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
> #/ echo "No not in the ocean -- *inside* the ocean."
> #/ cd /opt/rapids/cudf && py.test -v -x -k test_my_feature
> #/ exit
# Or a shortcut:
$ make rapids.run args="bash"
```

## Launch a notebook container with your file system mounted in
```bash
$ make notebooks.up
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

