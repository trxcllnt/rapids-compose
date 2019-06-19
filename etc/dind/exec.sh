#!/bin/sh -e

cd /opt/rapids/compose

args="";
file=${1:-""};

if [[ ! -z "${file// }" ]]; then shift; fi;

# Separate the `docker-compose exec` args from the dockerfile and service names

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d|--detach) args="${args:+$args }$1";;            # Detached mode: Run command in the background.
        --privileged) args="${args:+$args }$1";;           # Give extended privileges to the process.
        -T) args="${args:+$args }$1";;                     # Disable pseudo-tty allocation. By default `docker-compose exec` allocates a TTY.
        -u|--user) args="${args:+$args }$1 $2"; shift;;    # Run the command as this user.
        --index) args="${args:+$args }$1 $2"; shift;;      # index of the container if there are multiple instances of a service [default: 1]
        -e|--env) args="${args:+$args }$1 $2"; shift;;     # Set environment variables (can be used multiple times, not supported in API < 1.25)
        -w|--workdir) args="${args:+$args }$1 $2"; shift;; # Path to workdir directory for this command.
        --env-file) args="${args:+$args }$1 $2"; shift;;   # Specify an alternate environment file
        *) break;;
    esac; shift;
done

file="$file";
args="$args";
services=$*;

docker-compose -f $file exec $args $services;
