#!/bin/sh -e

cd "$COMPOSE_HOME"

args="";
file=${1:-""};

if [[ ! -z "${file// }" ]]; then shift; fi;

# Separate the `docker-compose up` args from the dockerfile and service names

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--detach) args="${args:+$args }$1";;                # Detached mode: Run containers in the background, print new container names. Incompatible with --abort-on-container-exit.
        --no-color) args="${args:+$args }$1";;                 # Produce monochrome output.
        --quiet-pull) args="${args:+$args }$1";;               # Pull without printing progress information
        --no-deps) args="${args:+$args }$1";;                  # Don't start linked services.
        --force-recreate) args="${args:+$args }$1";;           # Recreate containers even if their configuration and image haven't changed.
        --always-recreate-deps) args="${args:+$args }$1";;     # Recreate dependent containers. Incompatible with --no-recreate.
        --no-recreate) args="${args:+$args }$1";;              # If containers already exist, don't recreate them. Incompatible with --force-recreate and -V.
        --no-build) args="${args:+$args }$1";;                 # Don't build an image, even if it's missing.
        --no-start) args="${args:+$args }$1";;                 # Don't start the services after creating them.
        --build) args="${args:+$args }$1";;                    # Build images before starting containers.
        --abort-on-container-exit) args="${args:+$args }$1";;  # Stops all containers if any container was stopped. Incompatible with -d.
        -V|--renew-anon-volumes) args="${args:+$args }$1";;    # Recreate anonymous volumes instead of retrieving data from the previous containers.
        --remove-orphans) args="${args:+$args }$1";;           # Remove containers for services not defined in the Compose file.
        --scale) args="${args:+$args }$1 $2"; shift;;          # Scale SERVICE to NUM instances. Overrides the `scale` setting in the Compose file if present.
        --env-file) args="${args:+$args }$1 $2"; shift;;       # Specify an alternate environment file
        -t,|-timeout) args="${args:+$args }$1 $2"; shift;;     # Use this timeout in seconds for container shutdown when attached or when containers are already running. (default: 10)
        --exit-code-from) args="${args:+$args }$1 $2"; shift;; # Return the exit code of the selected service container. Implies --abort-on-container-exit.
        *) break;;
    esac; shift;
done

file="$file";
args="$args";
services=$*;

exec docker-compose -f $file up $args $services;
