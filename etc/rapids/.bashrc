shopt -s histappend;
export HISTCONTROL=ignoreboth;
export HISTSIZE=INFINITE;
export HISTFILESIZE=10000000;

export CCACHE_NOHASHDIR=
export CCACHE_DIR="$COMPOSE_HOME/etc/.ccache";
export CCACHE_COMPILERCHECK="%compiler% --version"
# Set this to debug ccache preprocessor errors and cache misses
# export CCACHE_LOGFILE="$COMPOSE_HOME/etc/.ccache/ccache.log";

source "$COMPOSE_HOME/etc/bash-utils.sh"

ninja-test() {
    test-cpp "$(find-cpp-build-home)"
}

export -f ninja-test;

pytest-debug() {
    python -m ptvsd --host 0.0.0.0 --port 5678 --wait -m pytest $*
}

export -f pytest-debug;
