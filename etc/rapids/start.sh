#!/usr/bin/env bash

set -Eeo pipefail

source "$RAPIDS_HOME/.bashrc"

# - ensure conda's installed
# - ensure the rapids conda env is created/updated/activated
source "$COMPOSE_HOME/etc/conda-install.sh" rapids

# activate the rapids conda environment on bash login
echo "export CONDA_DEFAULT_ENV=rapids \
   && source \"$RAPIDS_HOME/.bashrc\" >/dev/null 2>&1 \
   && source activate rapids >/dev/null 2>&1" \
> "$RAPIDS_HOME/.bash_login"

# If fresh conda env and cmd is build-rapids,
# do `clean-rapids` to delete build artifacts
[ "$FRESH_CONDA_ENV" == "1" ] \
 && [ "$(echo $@)" == "bash -c build-rapids" ] \
 && clean-rapids;

exec -l "$@"
