#!/bin/bash -e

cd "$COMPOSE_HOME"

args="";
file=${1:-""};

if [[ ! -z "${file// }" ]]; then shift; fi;

# Separate the `docker-compose run` args from the dockerfile and service names

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -T) args="${args:+$args }$1";;                     # Disable pseudo-tty allocation. By default `docker-compose run` allocates a TTY.
        --rm) args="${args:+$args }$1";;                   # Remove container after run. Ignored in detached mode.
        -d|--detach) args="${args:+$args }$1";;            # Detached mode: Run container in the background, print new container name.
        --no-deps) args="${args:+$args }$1";;              # Don't start linked services.
        --service-ports) args="${args:+$args }$1";;        # Run command with the service's ports enabled and mapped to the host.
        --use-aliases) args="${args:+$args }$1";;          # Use the service's network aliases in the network(s) the container connects to.
        --name) args="${args:+$args }$1 $2"; shift;;       # Assign a name to the container
        -e) args="${args:+$args }$1 $2"; shift;;           # Set an environment variable (can be used multiple times)
        --entrypoint) args="${args:+$args }$1 $2"; shift;; # Override the entrypoint of the image.
        -l|--label) args="${args:+$args }$1 $2"; shift;;   # Add or override a label (can be used multiple times)
        -p|--publish) args="${args:+$args }$1 $2"; shift;; # Publish a container's port(s) to the host
        -v|--volume) args="${args:+$args }$1 $2"; shift;;  # Bind mount a volume (default [])
        -u|--user) args="${args:+$args }$1 $2"; shift;;    # Run as specified username or uid
        -w|--workdir) args="${args:+$args }$1 $2"; shift;; # Working directory inside the container
        *) break;;
    esac; shift;
done

file="$file";
args="$args";
services=$*;

exec docker-compose -f $file run $args $services
