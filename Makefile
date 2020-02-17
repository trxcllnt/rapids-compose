SHELL := /bin/bash
PLATFORM := $(shell uname)
UID.Linux := $(shell id -u $$USER)
GID.Linux := $(shell id -g $$USER)
UID.Darwin := $(shell id -u $$USER)
GID.Darwin := $(shell id -g $$USER)
UID := $(or ${UID.${PLATFORM}}, 1000)
GID := $(or ${GID.${PLATFORM}}, 1000)

DEFAULT_CUDA_VERSION := 10.0
DEFAULT_PYTHON_VERSION := 3.7
DEFAULT_LINUX_VERSION := ubuntu18.04
DEFAULT_RAPIDS_NAMESPACE := $(shell echo $$USER)
DEFAULT_RAPIDS_VERSION := $(shell RES="" \
 && [ -z "$$RES" ] && RES=$$(cd ../cudf 2>/dev/null && git describe --abbrev=0 --tags) || true \
 && [ -z "$$RES" ] && [ -n `which curl` ] && [ -n `which jq` ] && RES=$$(curl -s https://api.github.com/repos/rapidsai/cudf/tags | jq -e -r ".[].name" 2>/dev/null | head -n1) || true \
 && echo $${RES:-"latest"})

.PHONY: all init rapids notebooks
		dind dc dc.up dc.run dc.exec dc.logs
		dc.build.rapids  dc.build.notebooks
		rapids.run rapids.exec rapids.logs
		rapids.cudf.run rapids.cudf.pytest rapids.cudf.pytest.debug
		notebooks.up notebooks.exec notebooks.logs

.SILENT: all init rapids notebooks
		 dind dc dc.up dc.run dc.exec dc.logs
		 dc.build.rapids  dc.build.notebooks
		 rapids.run rapids.exec rapids.logs
		 rapids.cudf.run rapids.cudf.pytest rapids.cudf.pytest.debug
		 notebooks.up notebooks.exec notebooks.logs

all: rapids notebooks

init:
	export CODE_REPOS="rmm cudf cuml cugraph" && \
	export ALL_REPOS="$$CODE_REPOS notebooks notebooks-contrib" && \
	export PYTHON_DIRS="rmm/python \
						cuml/python \
						cugraph/python \
						cudf/python/cudf \
						cudf/python/nvstrings \
						cudf/python/dask_cudf" && \
	touch ./etc/rapids/.bash_history && \
	bash -i ./scripts/01-install-dependencies.sh && \
	bash -i ./scripts/02-create-compose-env.sh && \
	bash -i ./scripts/03-create-vscode-workspace.sh && \
	bash -i ./scripts/04-clone-rapids-repositories.sh && \
	bash -i ./scripts/05-setup-c++-intellisense.sh && \
	bash -i ./scripts/06-setup-python-intellisense.sh && \
	[ -n "$$NEEDS_REBOOT" ] && echo "Installed new dependencies, please reboot to continue." \
	                || true && echo "RAPIDS workspace init success!"

rapids: dc.build.rapids
	@$(MAKE) -s dc.run svc="rapids" cmd_args="-u $(UID):$(GID)" svc_args="bash -c 'build-rapids'"

notebooks: dc.build.notebooks
	@$(MAKE) -s dc.run svc="notebooks" cmd_args="-u $(UID):$(GID)" svc_args="bash -c 'build-rapids'"

rapids.run: args ?=
rapids.run: cmd_args ?=
rapids.run: work_dir ?= /rapids
rapids.run:
	@$(MAKE) -s dc.run svc="rapids" svc_args="$(args)" cmd_args="-u $(UID):$(GID) -w $(work_dir) $(cmd_args)"

rapids.exec: args ?=
rapids.exec:
	@$(MAKE) -s dc.exec svc="rapids" svc_args="$(args)"

rapids.logs: args ?=
rapids.logs:
	@$(MAKE) -s dc.logs svc="rapids" svc_args="$(args)"

rapids.cudf.run: args ?=
rapids.cudf.run: cmd_args ?=
rapids.cudf.run: work_dir ?= /rapids/cudf
rapids.cudf.run:
	@$(MAKE) -s rapids.run work_dir="$(work_dir)" args="$(args)" cmd_args="$(cmd_args)"

rapids.cudf.pytest: args ?= -v -x
rapids.cudf.pytest:
	@$(MAKE) -s rapids.cudf.run work_dir="/rapids/cudf/python/cudf" args="pytest $(args)"

rapids.cudf.pytest.debug: args ?= -v -x
rapids.cudf.pytest.debug:
	@$(MAKE) -s rapids.cudf.run work_dir="/rapids/cudf/python/cudf" args="pytest-debug $(args)"

rapids.cudf.lint:
	@$(MAKE) -s rapids.cudf.run args="bash -c 'lint-rapids'"

notebooks.run: args ?=
notebooks.run: cmd_args ?=
notebooks.run:
	@$(MAKE) -s dc.run svc="notebooks" svc_args="$(args)" cmd_args="-u $(UID):$(GID) $(cmd_args)"

notebooks.up: args ?=
notebooks.up: cmd_args ?= -d
notebooks.up:
	@$(MAKE) -s dc.up svc="notebooks" svc_args="$(args)" cmd_args="$(cmd_args)"

notebooks.exec: args ?=
notebooks.exec: cmd_args ?=
notebooks.exec:
	@$(MAKE) -s dc.exec svc="notebooks" svc_args="$(args)" cmd_args="-u $(UID):$(GID) $(cmd_args)"

notebooks.logs: args ?=
notebooks.logs: cmd_args ?= -f
notebooks.logs:
	@$(MAKE) -s dc.logs svc="notebooks" svc_args="$(args)" cmd_args="$(cmd_args)"

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
dc: svc ?=
dc: args ?=
dc: cmd ?= build
dc: svc_args ?=
dc: cmd_args ?=
dc: file ?= docker-compose.yml
dc: dind
	set -a && . .env && set +a && \
	export RAPIDS_VERSION=$${RAPIDS_VERSION:-$(DEFAULT_RAPIDS_VERSION)} && \
	export RAPIDS_NAMESPACE=$${RAPIDS_NAMESPACE:-$(DEFAULT_RAPIDS_NAMESPACE)} && \
	docker run -it --rm --net=host --entrypoint "$$COMPOSE_HOME/etc/dind/$(cmd).sh" \
		-v "$$COMPOSE_HOME:$$COMPOSE_HOME" \
		-v "$$RAPIDS_HOME/rmm:$$RAPIDS_HOME/rmm" \
		-v "$$RAPIDS_HOME/cudf:$$RAPIDS_HOME/cudf" \
		-v "$$RAPIDS_HOME/cugraph:$$RAPIDS_HOME/cugraph" \
		-v "$$RAPIDS_HOME/notebooks:$$RAPIDS_HOME/notebooks" \
		-v "$$RAPIDS_HOME/notebooks-contrib:$$RAPIDS_HOME/notebooks-contrib" \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-e _UID=$${UID:-$(UID)} \
		-e _GID=$${GID:-$(GID)} \
		-e RAPIDS_HOME="$$RAPIDS_HOME" \
		-e CUDA_VERSION=$${CUDA_VERSION:-$(DEFAULT_CUDA_VERSION)} \
		-e LINUX_VERSION=$${LINUX_VERSION:-$(DEFAULT_LINUX_VERSION)} \
		-e PYTHON_VERSION=$${PYTHON_VERSION:-$(DEFAULT_PYTHON_VERSION)} \
		-e RAPIDS_VERSION=$${RAPIDS_VERSION:-$(DEFAULT_RAPIDS_VERSION)} \
		-e RAPIDS_NAMESPACE=$${RAPIDS_NAMESPACE:-$(DEFAULT_RAPIDS_NAMESPACE)} \
		"$$RAPIDS_NAMESPACE/rapids/dind:$$RAPIDS_VERSION" $(file) $(cmd_args) $(svc) $(svc_args)

dc.print_build_context:
	@$(MAKE) -s dc cmd="print_build_context"

dc.build: svc ?=
dc.build: svc_args ?=
dc.build: cmd_args ?= -f
dc.build: file ?= docker-compose.yml
dc.build:
	@$(MAKE) -s dc cmd="build"

dc.build.rapids:
	@$(MAKE) -s dc.build svc="rapids"

dc.build.notebooks:
	@$(MAKE) -s dc.build svc="notebooks"

dc.up: svc ?=
dc.up: svc_args ?=
dc.up: cmd_args ?=
dc.up: file ?= docker-compose.yml
dc.up:
	@$(MAKE) -s dc cmd="up"

dc.run: svc ?=
dc.run: svc_args ?=
dc.run: cmd_args ?=
dc.run: file ?= docker-compose.yml
dc.run:
	@$(MAKE) -s dc cmd="run" cmd_args="--rm $(cmd_args)"

dc.exec: svc ?=
dc.exec: svc_args ?=
dc.exec: cmd_args ?=
dc.exec: file ?= docker-compose.yml
dc.exec:
	@$(MAKE) -s dc cmd="exec"

dc.logs: svc ?=
dc.logs: svc_args ?=
dc.logs: cmd_args ?= -f
dc.logs: file ?= docker-compose.yml
dc.logs:
	@$(MAKE) -s dc cmd="logs"
