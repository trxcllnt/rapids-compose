#!/bin/sh -e

cd "$COMPOSE_HOME"

args="";
file=${1:-""};

if [[ ! -z "${file// }" ]]; then shift; fi;

# Separate the `docker-compose logs` args from the dockerfile and service names

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --no-color) args="${args:+$args }$1";;       # Produce monochrome output.
        -f|--follow) args="${args:+$args }$1";;      # Follow log output.
        -t|--timestamps) args="${args:+$args }$1";;  # Show timestamps.
        --tail) args="${args:+$args }$1 $2"; shift;; # Number of lines to show from the end of the logs for each container.
        *) break;;
    esac; shift;
done

file="$file";
args="$args";
services=$*;

docker-compose -f $file logs $args $services;
