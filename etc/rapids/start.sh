#!/usr/bin/env bash

set -Eeo pipefail

source /home/rapids/.bashrc
source "$COMPOSE_HOME/etc/bash-utils.sh"

# - ensure conda's installed
# - ensure the rapids conda env is created/updated
source "$COMPOSE_HOME/etc/conda-install.sh" rapids

# If fresh conda env and cmd is build.sh, run clean.sh
# first to delete build assets, artifacts, and caches
[ "$FRESH_CONDA_ENV" = "1" ] \
 && [ "$(echo $@)" = "compose/etc/rapids/build.sh" ] \
 && "$COMPOSE_HOME/etc/rapids/clean.sh";

# activate the rapids conda environment
source activate rapids

# activate the rapids conda environment on bash login
echo "source activate rapids" > /home/rapids/.bash_login

exec "$@"
