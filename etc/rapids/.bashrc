shopt -s histappend;
export HISTCONTROL=ignoreboth;
export HISTSIZE=INFINITE;
export HISTFILESIZE=10000000;
export CCACHE_DIR="$RAPIDS_HOME/compose/etc/.ccache";
ninja-test() {
    NAMES=${1:-""}; CTESTS=""; GTESTS="";
    for NAME in ${NAMES//,/ }; do
        CTESTS="${CTESTS:+$CTESTS|}$NAME";
        GTESTS="${GTESTS:+$GTESTS }gtests/$NAME";
    done;
    for x in "1"; do
        ninja -j$(nproc) $GTESTS || break;
        ctest --force-new-ctest-process \
              --output-on-failure \
              ${CTESTS:+-R $CTESTS} ${@:2} || break;
    done;
};
export -f ninja-test;
