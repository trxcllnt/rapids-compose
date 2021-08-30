#!/usr/bin/env bash

shopt -s globstar

SHOULD_RUN_BLACK=$(echo " $@ " | grep " --black " || echo "")
SHOULD_RUN_ISORT=$(echo " $@ " | grep " --isort " || echo "")
SHOULD_RUN_FLAKE8=$(echo " $@ " | grep " --flake8 " || echo "")

BLACK=""
BLACK_RETVAL="0"

ISORT=""
ISORT_RETVAL="0"

FLAKE8=""
FLAKE8_RETVAL="0"

FLAKE8_CYTHON=""
FLAKE8_CYTHON_RETVAL="0"

if [[ "$SHOULD_RUN_BLACK" != "" ]]; then
    if [[ "$SHOULD_RUN_ISORT" != "" ]]; then
        echo -e "Fixing imports..."
        isort --atomic python/**/*.py
        echo -e "Fixing python lint..."
        black python 2>/dev/null
        # Run isort and get results/return code
        ISORT=`isort --check-only python/**/*.py`
        ISORT_RETVAL=$?

        # Output results if failure otherwise show pass
        if [ "$ISORT_RETVAL" != "0" ]; then
            echo -e "\n\n>>>> FAILED: isort style check; begin output\n\n"
            echo -e "$ISORT"
            echo -e "\n\n>>>> FAILED: isort style check; end output\n\n"
        else
            echo -e ">>>> PASSED: isort style check"
        fi
    fi
    # Run black and get results/return code
    BLACK=`black -q --check python 2>/dev/null`
    BLACK_RETVAL=$?
    if [ "$BLACK_RETVAL" != "0" ]; then
        echo -e "\n\n>>>> FAILED: black style check; begin output\n\n"
        echo -e $(black --check --diff python)
        echo -e "\n\n>>>> FAILED: black style check; end output\n\n"
    else
        echo -e ">>>> PASSED: black style check"
    fi
fi

# Run flake8 and get results/return code
if [[ "$SHOULD_RUN_FLAKE8" != "" ]]; then

    FLAKE8_CONFIG="$(find python -type f -name '.flake8' | head -n1)"

    if [[ "$FLAKE8_CONFIG" != "" && -f "$FLAKE8_CONFIG" ]]; then
        # Run flake8-cython and get results/return code
        FLAKE8_CONFIG="$(realpath $FLAKE8_CONFIG)"
        FLAKE8=`flake8 python --exclude=cpp,thirdparty,_external_repositories,__init__.py,versioneer.py --config="$FLAKE8_CONFIG"`
        FLAKE8_RETVAL=$?
    else
        FLAKE8=`flake8 python --exclude=cpp,thirdparty,_external_repositories,__init__.py,versioneer.py`
        FLAKE8_RETVAL=$?
    fi

    if [ "$FLAKE8_RETVAL" != "0" ]; then
        echo -e "\n\n>>>> FAILED: flake8 style check; begin output\n\n"
        echo -e "$FLAKE8"
        echo -e "\n\n>>>> FAILED: flake8 style check; end output\n\n"
    else
        echo -e ">>>> PASSED: flake8 style check"
    fi

    FLAKE8_CYTHON_CONFIG="$(find python -type f -name '.flake8.cython' | head -n1)"

    if [[ "$FLAKE8_CYTHON_CONFIG" != "" && -f "$FLAKE8_CYTHON_CONFIG" ]]; then
        # Run flake8-cython and get results/return code
        FLAKE8_CYTHON_CONFIG="$(realpath $FLAKE8_CYTHON_CONFIG)"
        FLAKE8_CYTHON=`flake8 python --config="$FLAKE8_CYTHON_CONFIG"`
        FLAKE8_CYTHON_RETVAL=$?

        if [ "$FLAKE8_CYTHON_RETVAL" != "0" ]; then
            echo -e "\n\n>>>> FAILED: flake8-cython style check; begin output\n\n"
            echo -e "$FLAKE8_CYTHON"
            echo -e "\n\n>>>> FAILED: flake8-cython style check; end output\n\n"
        else
            echo -e ">>>> PASSED: flake8-cython style check"
        fi
    fi
fi

RETVALS=($ISORT_RETVAL $BLACK_RETVAL $FLAKE8_RETVAL $FLAKE8_CYTHON_RETVAL)
IFS=$'\n'
RETVAL=`echo "${RETVALS[*]}" | sort -nr | head -n1`

exit $RETVAL
