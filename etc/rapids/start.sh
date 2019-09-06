#!/usr/bin/env bash

set -e

source /home/rapids/.bashrc

# - ensure conda's installed
# - ensure the rapids conda env is created/updated
source "$RAPIDS_HOME/compose/etc/conda-install.sh" rapids

# If fresh conda env and cmd is build.sh, run clean.sh
# first to delete build assets, artifacts, and caches
[ "$FRESH_CONDA_ENV" = "1" ] \
 && [ "$(echo $@)" = "compose/etc/rapids/build.sh" ] \
 && "$RAPIDS_HOME/compose/etc/rapids/clean.sh";

# activate the rapids conda
source activate rapids

exec "$@"
