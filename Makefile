SHELL := /bin/bash
PLATFORM := $(shell uname)
UID.Linux := $(shell id -u $$USER)
GID.Linux := $(shell id -g $$USER)
UID.Darwin := $(shell id -u $$USER)
GID.Darwin := $(shell id -g $$USER)
UID := $(or ${UID.${PLATFORM}}, 1000)
GID := $(or ${GID.${PLATFORM}}, 1000)

CUDA_VERSION := $(shell echo $${CUDA_VERSION:-10.0})
PYTHON_VERSION := $(shell echo $${PYTHON_VERSION:-3.7})
LINUX_VERSION := $(shell echo $${LINUX_VERSION:-"ubuntu18.04"})

RAPIDS_NAMESPACE := $(shell echo $$USER)
RAPIDS_HOME := $(shell echo $${RAPIDS_HOME:-$$(realpath ..)})
RAPIDS_VERSION := $(shell cd ../cudf && echo "$$(git describe --abbrev=0 --tags 2>/dev/null || echo 'latest')")

.PHONY: all rapids notebooks
.SILENT: dind dc up run exec logs build rapids notebooks rapids.run rapids.exec rapids.logs rapids.cudf.run rapids.cudf.test rapids.cudf.test.debug notebooks.up notebooks.exec notebooks.logs

all: rapids notebooks

rapids:
	$(MAKE) dc svc="base" cmd="build"
	$(MAKE) dc svc="base" cmd="run"
	$(MAKE) dc svc="rapids" cmd="build"

notebooks: args ?=
notebooks: cmd_args ?=
notebooks:
	$(MAKE) dc.build svc="notebooks" svc_args=$(args) cmd_args=$(cmd_args)

notebooks.up: args ?=
notebooks.up: cmd_args ?= -d
notebooks.up:
	$(MAKE) dc.up svc="notebooks" svc_args=$(args) cmd_args=$(cmd_args)

notebooks.exec: args ?=
notebooks.exec: cmd_args ?=
notebooks.exec:
	$(MAKE) dc.exec svc="notebooks" svc_args=$(args) cmd_args=$(cmd_args)

notebooks.logs: args ?=
notebooks.logs: cmd_args ?= -f
notebooks.logs:
	$(MAKE) dc.logs svc="notebooks" svc_args=$(args) cmd_args=$(cmd_args)

rapids.run: args ?=
rapids.run:
	$(MAKE) dc.run svc="rapids" svc_args=$(args)

rapids.exec: args ?=
rapids.exec:
	$(MAKE) dc.exec svc="rapids" svc_args=$(args)

rapids.logs: args ?=
rapids.logs:
	$(MAKE) dc.logs svc="rapids" svc_args=$(args)

rapids.cudf.run: args ?=
rapids.cudf.run: cmd_args ?=
rapids.cudf.run:
	$(MAKE) dc.run svc="rapids" svc_args="$(args)" cmd_args="-w /opt/rapids/cudf $(cmd_args) -u $(UID):$(GID)"

rapids.cudf.test: expr ?= test_
rapids.cudf.test: args ?= pytest --full-trace -v -x
rapids.cudf.test:
	$(MAKE) rapids.cudf.run args="$(args) -k $(expr)"

rapids.cudf.test.debug: expr ?= test_
rapids.cudf.test.debug: args ?= pytest --full-trace -v -x
rapids.cudf.test.debug:
	$(MAKE) rapids.cudf.run args="python -m ptvsd --host 0.0.0.0 --port 5678 --wait -m $(args) -k $(expr)"
	docker network inspect compose_default | jq -c \
		'.[].Containers | to_entries | .[].value | select(.Name | startswith("compose_rapids")) | .IPv4Address | "Debugger listening at: \(.[0:-3])"'

# Build the docker-in-docker container
dind: docker_version ?= $(shell docker --version | cut -d' ' -f3 | cut -d',' -f1)
dind:
	docker build \
		-q --build-arg DOCKER_VERSION=$(docker_version) \
		-t $(RAPIDS_NAMESPACE)/rapids/dind:$(RAPIDS_VERSION) \
		-f dockerfiles/dind.Dockerfile .

# Run docker-compose inside the docker-in-docker container
dc: svc ?=
dc: args ?=
dc: cmd ?= build
dc: svc_args ?=
dc: cmd_args ?=
dc: file ?= docker-compose.yml
dc: dind
	set -a && . .localpaths && set +a && \
	docker run -it --rm --entrypoint "/opt/rapids/compose/etc/dind/$(cmd).sh" \
		-e _UID=$(UID) \
		-e _GID=$(GID) \
		-e CUDA_VERSION=$(CUDA_VERSION) \
		-e LINUX_VERSION=$(LINUX_VERSION) \
		-e PYTHON_VERSION=$(PYTHON_VERSION) \
		-e RAPIDS_VERSION=$(RAPIDS_VERSION) \
		-e RAPIDS_NAMESPACE=$(RAPIDS_NAMESPACE) \
		-e COMPOSE_SOURCE="$$COMPOSE_SOURCE" \
		-e RMM_SOURCE="$$RMM_SOURCE" \
		-e CUDF_SOURCE="$$CUDF_SOURCE" \
		-e CUGRAPH_SOURCE="$$CUGRAPH_SOURCE" \
		-e CUSTRINGS_SOURCE="$$CUSTRINGS_SOURCE" \
		-e NOTEBOOKS_SOURCE="$$NOTEBOOKS_SOURCE" \
		-e NOTEBOOKS_EXTENDED_SOURCE="$$NOTEBOOKS_EXTENDED_SOURCE" \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v "$$COMPOSE_SOURCE":/opt/rapids/compose \
		-v "$$RMM_SOURCE":/opt/rapids/rmm \
		-v "$$CUDF_SOURCE":/opt/rapids/cudf \
		-v "$$CUGRAPH_SOURCE":/opt/rapids/cugraph \
		-v "$$CUSTRINGS_SOURCE":/opt/rapids/custrings \
		-v "$$NOTEBOOKS_SOURCE":/opt/rapids/notebooks \
		-v "$$NOTEBOOKS_EXTENDED_SOURCE":/opt/rapids/notebooks-extended \
		$(RAPIDS_NAMESPACE)/rapids/dind:$(RAPIDS_VERSION) $(file) $(cmd_args) $(svc) $(svc_args)

dc.build: svc ?=
dc.build: svc_args ?=
dc.build: cmd_args ?= -f
dc.build: file ?= docker-compose.yml
dc.build:
	$(MAKE) dc cmd="build"

dc.up: svc ?=
dc.up: svc_args ?=
dc.up: cmd_args ?=
dc.up: file ?= docker-compose.yml
dc.up:
	$(MAKE) dc cmd="up"

dc.run: svc ?=
dc.run: svc_args ?=
dc.run: cmd_args ?=
dc.run: file ?= docker-compose.yml
dc.run:
	$(MAKE) dc cmd="run" cmd_args="--rm $(cmd_args)"

dc.exec: svc ?=
dc.exec: svc_args ?=
dc.exec: cmd_args ?=
dc.exec: file ?= docker-compose.yml
dc.exec:
	$(MAKE) dc cmd="exec"

dc.logs: svc ?=
dc.logs: svc_args ?=
dc.logs: cmd_args ?= -f
dc.logs: file ?= docker-compose.yml
dc.logs:
	$(MAKE) dc cmd="logs"
