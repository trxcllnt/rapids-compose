#!/bin/sh -e

cd /opt/rapids/compose

args="";
file=${1:-""};

if [[ ! -z "${file// }" ]]; then shift; fi;

# Separate the `docker-compose build` args from the dockerfile and service names

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --compress) args="${args:+$args }$1";; # Compress the build context using gzip.
        --force-rm) args="${args:+$args }$1";; # Always remove intermediate containers.
        --no-cache) args="${args:+$args }$1";; # Do not use cache when building the image.
        --no-rm) args="${args:+$args }$1";; # Do not remove intermediate containers after a successful build.
        --pull) args="${args:+$args }$1";; # Always attempt to pull a newer version of the image.
        --parallel) args="${args:+$args }$1";; # Build images in parallel.
        -q|--quiet) args="${args:+$args }$1";; # Don't print anything to STDOUT
        --build-arg) args="${args:+$args }$1 $2"; shift;; # Set build-time variables for services.
        -m|--memory) args="${args:+$args }$1 $2"; shift;; # Sets memory limit for the build container.
        *) break;;
    esac; shift;
done

file="$file";
args="$args";
services=$*;

docker-compose -f $file build $args $services;

if [ "$file" = "compose.base.yml" ]; then
    sh /opt/rapids/compose/etc/dind/copy-build-assets.sh
fi;
