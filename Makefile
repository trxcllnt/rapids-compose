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
DEFAULT_RAPIDS_VERSION := $(shell cd ../cudf && echo "$$(git describe --abbrev=0 --tags 2>/dev/null || echo 'latest')")

.PHONY: all build rapids notebooks
.SILENT: dind dc up run exec logs build rapids notebooks rapids.run rapids.exec rapids.logs rapids.cudf.run rapids.cudf.test rapids.cudf.test.debug notebooks.up notebooks.exec notebooks.logs

all: build rapids
# all: build rapids notebooks

build:
	@$(MAKE) -s dc.build svc="rapids"

rapids: build
	@$(MAKE) -s dc.run svc="rapids" cmd_args="-u $(UID):$(GID)"

# notebooks: args ?=
# notebooks: cmd_args ?=
# notebooks:
# 	@$(MAKE) -s dc.build svc="notebooks" svc_args=$(args) cmd_args=$(cmd_args)

# notebooks.up: args ?=
# notebooks.up: cmd_args ?= -d
# notebooks.up:
# 	@$(MAKE) -s dc.up svc="notebooks" svc_args=$(args) cmd_args=$(cmd_args)

# notebooks.exec: args ?=
# notebooks.exec: cmd_args ?=
# notebooks.exec:
# 	@$(MAKE) -s dc.exec svc="notebooks" svc_args=$(args) cmd_args=$(cmd_args)

# notebooks.logs: args ?=
# notebooks.logs: cmd_args ?= -f
# notebooks.logs:
# 	@$(MAKE) -s dc.logs svc="notebooks" svc_args=$(args) cmd_args=$(cmd_args)

rapids.run: args ?=
rapids.run: cmd_args ?=
rapids.run:
	@$(MAKE) -s dc.run svc="rapids" svc_args=$(args) cmd_args="$(cmd_args) -u $(id -u):$(id -g)"

rapids.exec: args ?=
rapids.exec:
	@$(MAKE) -s dc.exec svc="rapids" svc_args=$(args)

rapids.logs: args ?=
rapids.logs:
	@$(MAKE) -s dc.logs svc="rapids" svc_args=$(args)

rapids.cudf.run: args ?=
rapids.cudf.run: cmd_args ?=
rapids.cudf.run:
	@$(MAKE) -s dc.run svc="rapids" svc_args="$(args)" cmd_args="-w /rapids/cudf $(cmd_args) -u $(UID):$(GID)"

rapids.cudf.test: args ?= -v -x
rapids.cudf.test:
	@$(MAKE) -s rapids.cudf.run args="pytest $(args) ."

rapids.cudf.test.debug: args ?= -v -x
rapids.cudf.test.debug:
	@$(MAKE) -s rapids.cudf.run args="python -m ptvsd --host 0.0.0.0 --port 5678 --wait -m pytest $(args) ."

rapids.cudf.lint:
	@$(MAKE) -s rapids.cudf.run cmd_args="--entrypoint /rapids/compose/etc/check-style.sh"

# Build the docker-in-docker container
dind: docker_version ?= $(shell docker --version | cut -d' ' -f3 | cut -d',' -f1)
dind:
	set -a && . .env && set +a && \
	export RAPIDS_VERSION=$${RAPIDS_VERSION:-$(DEFAULT_RAPIDS_VERSION)} && \
	export RAPIDS_NAMESPACE=$${RAPIDS_NAMESPACE:-$(DEFAULT_RAPIDS_NAMESPACE)} && \
	docker build -q \
		--build-arg RAPIDS_HOME="$$RAPIDS_HOME" \
		--build-arg DOCKER_VERSION=$(docker_version) \
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
	docker run -it --rm --entrypoint "$$RAPIDS_HOME/compose/etc/dind/$(cmd).sh" \
		-v "$$RAPIDS_HOME/rmm:$$RAPIDS_HOME/rmm" \
		-v "$$RAPIDS_HOME/cudf:$$RAPIDS_HOME/cudf" \
		-v "$$RAPIDS_HOME/compose:$$RAPIDS_HOME/compose" \
		-v "$$RAPIDS_HOME/cugraph:$$RAPIDS_HOME/cugraph" \
		-v "$$RAPIDS_HOME/custrings:$$RAPIDS_HOME/custrings" \
		-v "$$RAPIDS_HOME/notebooks:$$RAPIDS_HOME/notebooks" \
		-v "$$RAPIDS_HOME/notebooks-extended:$$RAPIDS_HOME/notebooks-extended" \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-e _UID=$${UID:-$(UID)} \
		-e _GID=$${GID:-$(GID)} \
		-e LINES=$(shell tput lines) \
		-e COLUMNS=$(shell tput cols) \
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
