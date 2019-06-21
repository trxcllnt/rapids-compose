#!/bin/sh -e

host_bridge() {
    mkdir -p "$1" && rmdir "$1" && ln -s "$2" "$1"
}

host_bridge "$COMPOSE_SOURCE" /opt/rapids/compose
host_bridge "$RMM_SOURCE" /opt/rapids/rmm
host_bridge "$CUDF_SOURCE" /opt/rapids/cudf
host_bridge "$CUGRAPH_SOURCE" /opt/rapids/cugraph
host_bridge "$CUSTRINGS_SOURCE" /opt/rapids/custrings
host_bridge "$NOTEBOOKS_SOURCE" /opt/rapids/notebooks
host_bridge "$NOTEBOOKS_EXTENDED_SOURCE" /opt/rapids/notebooks-extended
