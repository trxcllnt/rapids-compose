SHELL := /bin/bash
PLATFORM := $(shell uname)
UID.Linux := $(shell id -u $$USER)
GID.Linux := $(shell id -g $$USER)
UID.Darwin := $(shell id -u $$USER)
GID.Darwin := $(shell id -g $$USER)
UID := $(or ${UID.${PLATFORM}}, 1000)
GID := $(or ${GID.${PLATFORM}}, 1000)

CUDA_VERSION := $(shell echo $${CUDA_VERSION:-10.0})
LINUX_VERSION := $(shell echo $${LINUX_VERSION:-"ubuntu18.04"})

RAPIDS_NAMESPACE := $(shell echo $$USER)
RAPIDS_HOME := $(shell echo $${RAPIDS_HOME:-$$(realpath ..)})
RAPIDS_VERSION := $(shell cd ../cudf && echo "$$(git describe --abbrev=0 --tags 2>/dev/null || echo 'latest')")

.SILENT: dc dind dc.dind up run exec logs build base rapids rapids.run rapids.exec rapids.logs test.cudf debug.cudf notebooks notebooks.up notebooks.exec notebooks.logs

dc: cmd ?=
dc: svc ?=
dc: cmd_args ?=
dc: svc_args ?=
dc: file ?= docker-compose.yml
dc:
	set -a && . .localpaths && set +a && \
	_UID=$(UID) \
	_GID=$(GID) \
	CUDA_VERSION=$(CUDA_VERSION) \
	LINUX_VERSION=$(LINUX_VERSION) \
	RAPIDS_VERSION=$(RAPIDS_VERSION) \
	RAPIDS_NAMESPACE=$(RAPIDS_NAMESPACE) \
	docker-compose -f $(file) $(cmd) $(cmd_args) $(svc) $(svc_args)



# Build the docker-in-docker container
dind: docker_version ?= $(shell docker --version | cut -d' ' -f3 | cut -d',' -f1)
dind:
	docker build \
		-q --build-arg DOCKER_VERSION=$(docker_version) \
		-t $(RAPIDS_NAMESPACE)/rapids/dind:$(RAPIDS_VERSION) \
		-f dockerfiles/dind.Dockerfile .


# Run docker-compose inside the docker-in-docker container
dc.dind: svc ?=
dc.dind: args ?=
dc.dind: cmd ?= build
dc.dind: svc_args ?=
dc.dind: cmd_args ?=
dc.dind: file ?= docker-compose.yml
dc.dind: dind
	set -a && . .localpaths && set +a && \
	docker run -it --rm --entrypoint "/opt/rapids/compose/etc/dind/$(cmd).sh" \
	    -e _UID=$(UID) \
	    -e _GID=$(GID) \
	    -e CUDA_VERSION=$(CUDA_VERSION) \
	    -e LINUX_VERSION=$(LINUX_VERSION) \
	    -e RAPIDS_VERSION=$(RAPIDS_VERSION) \
	    -e RAPIDS_NAMESPACE=$(RAPIDS_NAMESPACE) \
	    -v /var/run/docker.sock:/var/run/docker.sock \
	    -v "$$COMPOSE_SOURCE":/opt/rapids/compose \
	    -v "$$RMM_SOURCE":/opt/rapids/rmm \
	    -v "$$CUDF_SOURCE":/opt/rapids/cudf \
	    -v "$$CUGRAPH_SOURCE":/opt/rapids/cugraph \
	    -v "$$CUSTRINGS_SOURCE":/opt/rapids/custrings \
	    -v "$$NOTEBOOKS_SOURCE":/opt/rapids/notebooks \
	    -v "$$NOTEBOOKS_EXTENDED_SOURCE":/opt/rapids/notebooks-extended \
	    $(RAPIDS_NAMESPACE)/rapids/dind:$(RAPIDS_VERSION) $(file) $(cmd_args) $(svc) $(svc_args)


up: svc ?=
up: svc_args ?=
up: cmd_args ?=
up: file ?= docker-compose.yml
up:
	$(MAKE) dc cmd="up"

run: svc ?=
run: svc_args ?=
run: cmd_args ?=
run: file ?= docker-compose.yml
run:
	$(MAKE) dc cmd="run" cmd_args="--rm $(cmd_args)"

exec: svc ?=
exec: svc_args ?=
exec: cmd_args ?=
exec: file ?= docker-compose.yml
exec:
	$(MAKE) dc cmd="exec"

logs: svc ?=
logs: svc_args ?=
logs: cmd_args ?= -f
logs: file ?= docker-compose.yml
logs:
	$(MAKE) dc cmd="logs"


build: svc ?=
build: svc_args ?=
build: cmd_args ?= -f
build: file ?= docker-compose.yml
build:
	$(MAKE) dc.dind cmd="build"


base: svc_args ?=
base: cmd_args ?=
base:
	$(MAKE) build file="compose.base.yml"




rapids: svc_args ?=
rapids: cmd_args ?=
rapids: base
	$(MAKE) build svc="rapids"

rapids.run: args ?=
rapids.run:
	$(MAKE) run svc="rapids" svc_args=$(args)

rapids.exec: args ?=
rapids.exec:
	$(MAKE) exec svc="rapids" svc_args=$(args)

rapids.logs: args ?=
rapids.logs:
	$(MAKE) logs svc="rapids" svc_args=$(args)

test.cudf: expr ?= test_
test.cudf: args ?= pytest --full-trace -v -x
test.cudf:
	$(MAKE) run svc="rapids" svc_args="$(args) -k $(expr)" cmd_args="-w /opt/rapids/cudf"

debug.cudf: expr ?= test_
debug.cudf: args ?= pytest --full-trace -v -x
debug.cudf:
	$(MAKE) rapids.run \
		cmd_args="-d -w /opt/rapids/cudf" \
		args="python -m ptvsd --host 0.0.0.0 --port 5678 --wait -m $(args) -k $(expr)"
	docker network inspect compose_default | jq -c \
		'.[].Containers | to_entries | .[].value | select(.Name | startswith("compose_rapids")) | .IPv4Address | "Debugger listening at: \(.[0:-3])"'




notebooks: svc_args ?=
notebooks: cmd_args ?=
notebooks: rapids
	$(MAKE) build svc="notebooks" svc_args=$(svc_args) cmd_args=$(cmd_args)

notebooks.up: svc_args ?=
notebooks.up: cmd_args ?= -d
notebooks.up:
	$(MAKE) up svc="notebooks" svc_args=$(svc_args) cmd_args=$(cmd_args)

notebooks.exec: svc_args ?=
notebooks.exec: cmd_args ?=
notebooks.exec:
	$(MAKE) exec svc="notebooks" svc_args=$(svc_args) cmd_args=$(cmd_args)

notebooks.logs: svc_args ?=
notebooks.logs: cmd_args ?= -f
notebooks.logs:
	$(MAKE) logs svc="notebooks" svc_args=$(svc_args) cmd_args=$(cmd_args)
