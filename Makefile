SHELL := /bin/bash
PLATFORM := $(shell uname)
UID.Linux := $(shell id -u $$USER)
GID.Linux := $(shell id -g $$USER)
UID.Darwin := $(shell id -u $$USER)
GID.Darwin := $(shell id -g $$USER)
UID := $(or ${UID.${PLATFORM}}, 1000)
GID := $(or ${GID.${PLATFORM}}, 1000)

# define a "make in quiet mode" shortcut to hide
# superfluous entering/exiting directory messages
MAKE_Q := $(MAKE) --no-print-directory

DEFAULT_CUDA_VERSION := 11.2.0
DEFAULT_PYTHON_VERSION := 3.7
DEFAULT_LINUX_VERSION := ubuntu18.04
DEFAULT_RAPIDS_NAMESPACE := $(shell echo $$USER)
DEFAULT_RAPIDS_VERSION := $(shell RES="" \
 && [ -z "$$RES" ] && [ -n `which curl` ] && [ -n `which jq` ] && RES=$$(curl -s https://api.github.com/repos/rapidsai/cudf/tags | jq -e -r ".[].name" 2>/dev/null | head -n1) || true \
 && echo $${RES:-"latest"})

.PHONY: init rapids notebooks rapids.build rapids.run rapids.exec rapids.logs rapids.cudf.run rapids.cudf.pytest rapids.cudf.pytest.debug notebooks.build notebooks.run notebooks.up notebooks.exec notebooks.logs dind dc dc.up dc.run dc.dind dc.exec dc.logs dc.apt.cacher.up

.SILENT: init rapids notebooks rapids.build rapids.run rapids.exec rapids.logs rapids.cudf.run rapids.cudf.pytest rapids.cudf.pytest.debug notebooks.build notebooks.run notebooks.up notebooks.exec notebooks.logs dind dc dc.up dc.run dc.dind dc.exec dc.logs dc.apt.cacher.up

all: rapids

rapids: rapids.build
	@$(MAKE_Q) dc.run svc="rapids" cmd_args="-u $(UID):$(GID)" svc_args="bash -c 'build-rapids'"

notebooks: notebooks.build
	@$(MAKE_Q) dc.run svc="notebooks" cmd_args="-u $(UID):$(GID)" svc_args="echo 'notebooks build complete'"

rapids.build:
	@$(MAKE_Q) dc.build svc="rapids"

rapids.run: args ?=
rapids.run: cmd_args ?=
rapids.run: work_dir ?= /rapids
rapids.run: dc.apt.cacher.up
	@$(MAKE_Q) dc.run svc="rapids" svc_args="$(args)" cmd_args="-u $(UID):$(GID) -w $(work_dir) $(cmd_args)"

rapids.exec: args ?=
rapids.exec:
	@$(MAKE_Q) dc.exec svc="rapids" svc_args="$(args)"

rapids.logs: args ?=
rapids.logs: cmd_args ?= -f
rapids.logs:
	@$(MAKE_Q) dc.logs svc="rapids" svc_args="$(args)" cmd_args="$(cmd_args)"

notebooks.build:
	@$(MAKE_Q) dc.build svc="notebooks"

notebooks.run: args ?=
notebooks.run: cmd_args ?=
notebooks.run:
	@$(MAKE_Q) dc.run svc="notebooks" svc_args="$(args)" cmd_args="-u $(UID):$(GID) $(cmd_args)"

notebooks.up: args ?=
notebooks.up: cmd_args ?= -d
notebooks.up:
	@$(MAKE_Q) dc.up svc="notebooks" svc_args="$(args)" cmd_args="$(cmd_args)"

notebooks.exec: args ?=
notebooks.exec: cmd_args ?=
notebooks.exec:
	@$(MAKE_Q) dc.exec svc="notebooks" svc_args="$(args)" cmd_args="-u $(UID):$(GID) $(cmd_args)"

notebooks.logs: args ?=
notebooks.logs: cmd_args ?= -f
notebooks.logs:
	@$(MAKE_Q) dc.logs svc="notebooks" svc_args="$(args)" cmd_args="$(cmd_args)"

dc.apt.cacher.up:
	@$(MAKE_Q) dc.up svc="apt-cacher-ng" cmd_args="-d"

dc.build: svc ?=
dc.build: svc_args ?=
dc.build: cmd_args ?= --pull --force-rm
dc.build: file ?= docker-compose.yml
dc.build: dc.apt.cacher.up
	@$(MAKE_Q) dc.dind cmd="build"

dc.up: svc ?=
dc.up: svc_args ?=
dc.up: cmd_args ?=
dc.up: file ?= docker-compose.yml
dc.up:
	@$(MAKE_Q) dc cmd="up"

dc.run: svc ?=
dc.run: svc_args ?=
dc.run: cmd_args ?=
dc.run: file ?= docker-compose.yml
dc.run:
	@$(MAKE_Q) dc cmd="run" cmd_args="--rm $(cmd_args)"

dc.exec: svc ?=
dc.exec: svc_args ?=
dc.exec: cmd_args ?=
dc.exec: file ?= docker-compose.yml
dc.exec:
	@$(MAKE_Q) dc cmd="exec"

dc.logs: svc ?=
dc.logs: svc_args ?=
dc.logs: cmd_args ?= -f
dc.logs: file ?= docker-compose.yml
dc.logs:
	@$(MAKE_Q) dc cmd="logs"

# Run docker-compose
dc: svc ?=
dc: args ?=
dc: cmd ?= build
dc: svc_args ?=
dc: cmd_args ?=
dc: file ?= docker-compose.yml
dc:
	set -a && . .env && set +a && \
	env	_UID=$${UID:-$(UID)} \
		_GID=$${GID:-$(GID)} \
		RAPIDS_HOME="$$RAPIDS_HOME" \
		COMPOSE_HOME="$$COMPOSE_HOME" \
		PARALLEL_LEVEL=$${PARALLEL_LEVEL:-$(shell nproc --ignore=2)} \
		CUDA_VERSION=$${CUDA_VERSION:-$(DEFAULT_CUDA_VERSION)} \
		LINUX_VERSION=$${LINUX_VERSION:-$(DEFAULT_LINUX_VERSION)} \
		PYTHON_VERSION=$${PYTHON_VERSION:-$(DEFAULT_PYTHON_VERSION)} \
		RAPIDS_VERSION=$${RAPIDS_VERSION:-$(DEFAULT_RAPIDS_VERSION)} \
		RAPIDS_NAMESPACE=$${RAPIDS_NAMESPACE:-$(DEFAULT_RAPIDS_NAMESPACE)} \
		CONDA_CUDA_TOOLKIT_VERSION=$${CONDA_CUDA_TOOLKIT_VERSION:-$$CUDA_VERSION} \
		docker-compose -f $(file) $(cmd) $(cmd_args) $(svc) $(svc_args)

init:
	export CODE_REPOS="rmm raft cudf cuml cugraph cuspatial" && \
	export ALL_REPOS="$$CODE_REPOS notebooks-contrib" && \
	export PYTHON_DIRS="rmm/python \
						raft/python \
						cuml/python \
						cugraph/python \
						cudf/python/cudf \
						cudf/python/dask_cudf \
						cuspatial/python/cuspatial" && \
	touch ./etc/rapids/.bash_history;
	source ./scripts/01-install-dependencies.sh;
	bash -i ./scripts/02-create-compose-env.sh;
	bash -i ./scripts/03-create-vscode-workspace.sh;
	bash -i ./scripts/04-clone-rapids-repositories.sh;
	bash -i ./scripts/05-setup-c++-intellisense.sh;
	bash -i ./scripts/06-setup-python-intellisense.sh;
	[ -n "$$NEEDS_REBOOT" ] && echo "Installed docker, please reboot to continue." \
	                || true && echo "RAPIDS workspace init success!"

# Run a docker container that prints the build context size and top ten largest folders
dc.print_build_context:
	@$(MAKE_Q) dc.dind cmd="print_build_context"

# Build the docker-in-docker container
dind:
	set -a && . .env && set +a && \
	export RAPIDS_VERSION=$${RAPIDS_VERSION:-$(DEFAULT_RAPIDS_VERSION)} && \
	export RAPIDS_NAMESPACE=$${RAPIDS_NAMESPACE:-$(DEFAULT_RAPIDS_NAMESPACE)} && \
	docker build -q \
		--build-arg RAPIDS_HOME="$$RAPIDS_HOME" \
		--build-arg COMPOSE_HOME="$$COMPOSE_HOME" \
		-t "$$RAPIDS_NAMESPACE/rapids/dind:$$RAPIDS_VERSION" \
		-f dockerfiles/dind.Dockerfile .

# Run docker-compose inside the docker-in-docker container
dc.dind: svc ?=
dc.dind: args ?=
dc.dind: cmd ?= build
dc.dind: svc_args ?=
dc.dind: cmd_args ?=
dc.dind: file ?= docker-compose.yml
dc.dind: dind
	set -a && . .env && set +a && \
	export RAPIDS_VERSION=$${RAPIDS_VERSION:-$(DEFAULT_RAPIDS_VERSION)} && \
	export RAPIDS_NAMESPACE=$${RAPIDS_NAMESPACE:-$(DEFAULT_RAPIDS_NAMESPACE)} && \
	docker run -it --rm --net=host --entrypoint "$$COMPOSE_HOME/etc/dind/$(cmd).sh" \
		-v "$$COMPOSE_HOME:$$COMPOSE_HOME" \
		-v "$$RAPIDS_HOME/rmm:$$RAPIDS_HOME/rmm" \
		-v "$$RAPIDS_HOME/cudf:$$RAPIDS_HOME/cudf" \
		-v "$$RAPIDS_HOME/cuml:$$RAPIDS_HOME/cuml" \
		-v "$$RAPIDS_HOME/cugraph:$$RAPIDS_HOME/cugraph" \
		-v "$$RAPIDS_HOME/cuspatial:$$RAPIDS_HOME/cuspatial" \
		-v "$$RAPIDS_HOME/notebooks-contrib:$$RAPIDS_HOME/notebooks-contrib" \
		-v "$${DOCKER_HOST:-/var/run/docker.sock}:$${DOCKER_HOST:-/var/run/docker.sock}" \
		-v "/tmp/.X11-unix:/tmp/.X11-unix:rw" \
		-v "/usr/share/fonts:/usr/share/fonts:ro" \
		-v "$${XDG_RUNTIME_DIR-/run/user/$$UID}:$${XDG_RUNTIME_DIR-/run/user/$$UID}" \
		-v "/run/dbus/system_bus_socket:/run/dbus/system_bus_socket" \
		-e _UID=$${UID:-$(UID)} \
		-e _GID=$${GID:-$(GID)} \
		-e RAPIDS_HOME="$$RAPIDS_HOME" \
		-e DISPLAY="$$DISPLAY" \
		-e XAUTHORITY="$$XAUTHORITY" \
		-e XDG_RUNTIME_DIR="$$XDG_RUNTIME_DIR" \
		-e XDG_SESSION_TYPE="$$XDG_SESSION_TYPE" \
		-e DBUS_SESSION_BUS_ADDRESS="$$DBUS_SESSION_BUS_ADDRESS" \
		-e PARALLEL_LEVEL=$${PARALLEL_LEVEL:-$(shell nproc --ignore=2)} \
		-e CUDA_VERSION=$${CUDA_VERSION:-$(DEFAULT_CUDA_VERSION)} \
		-e LINUX_VERSION=$${LINUX_VERSION:-$(DEFAULT_LINUX_VERSION)} \
		-e PYTHON_VERSION=$${PYTHON_VERSION:-$(DEFAULT_PYTHON_VERSION)} \
		-e RAPIDS_VERSION=$${RAPIDS_VERSION:-$(DEFAULT_RAPIDS_VERSION)} \
		-e RAPIDS_NAMESPACE=$${RAPIDS_NAMESPACE:-$(DEFAULT_RAPIDS_NAMESPACE)} \
		-e CONDA_CUDA_TOOLKIT_VERSION=$${CONDA_CUDA_TOOLKIT_VERSION:-$$CUDA_VERSION} \
		"$$RAPIDS_NAMESPACE/rapids/dind:$$RAPIDS_VERSION" $(file) $(cmd_args) $(svc) $(svc_args)
