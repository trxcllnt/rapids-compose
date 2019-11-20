shopt -s histappend;
export HISTCONTROL=ignoreboth;
export HISTSIZE=INFINITE;
export HISTFILESIZE=10000000;
export CCACHE_DIR="$RAPIDS_HOME/compose/etc/.ccache";

ninja-test() {
    update-environment-variables;
    cd "$(find-cpp-build-home)";
    CTESTS="";
    GTESTS="";
    ###
    # Parse the test names from the input args. Assume all arguments up to
    # a double-dash (`--`) or dash-prefixed (`-*`) argument are test names,
    # and all arguments after are ctest arguments. Strip `--` (if found)
    # from the args list before passing the args to ctest. Example:
    #
    # $ ninja-test TEST_1,TEST_2 gtests/TEST_3 -- --verbose --parallel
    # $ ninja-test gtests/TEST_1 gtests/TEST_2 gtests/TEST_3 --verbose --parallel
    ###
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --) shift; break;;
            -*) break;;
            *) NAMES=${1:-""};
               for NAME in ${NAMES//,/ }; do
                   NAME="${NAME#gtests/}";
                   CTESTS="${CTESTS:+$CTESTS|}$NAME";
                   GTESTS="${GTESTS:+$GTESTS }gtests/$NAME";
               done;;
        esac; shift;
    done
    for x in "1"; do
        ninja -j$(nproc) $GTESTS || break;
        ctest --force-new-ctest-process \
              --output-on-failure \
              ${CTESTS:+-R $CTESTS} $* || break;
    done;
};
export -f ninja-test;

pytest-debug() {
    python -m ptvsd --host 0.0.0.0 --port 5678 --wait -m pytest $*
}
export -f pytest-debug;
