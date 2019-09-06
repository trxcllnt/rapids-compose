#!/usr/bin/env bash

set -e

echo -e "\nrunning \`isort --recursive --atomic python\`"
isort --recursive --atomic python
echo -e "\nrunning \`black python 2>/dev/null\`"
black python 2>/dev/null

# Run isort and get results/return code
ISORT=`isort --recursive --check-only python`
ISORT_RETVAL=$?

# Run black and get results/return code
BLACK=`black -q --check python 2>/dev/null`
BLACK_RETVAL=$?

# Run flake8 and get results/return code
FLAKE=`flake8 python`
FLAKE_RETVAL=$?

# Run flake8-cython and get results/return code
FLAKE_CYTHON=`flake8 --config=python/cudf/.flake8.cython`
FLAKE_CYTHON_RETVAL=$?

# Output results if failure otherwise show pass
if [ "$ISORT_RETVAL" != "0" ]; then
  echo -e "\n\n>>>> FAILED: isort style check; begin output\n\n"
  echo -e "$ISORT"
  echo -e "\n\n>>>> FAILED: isort style check; end output\n\n"
else
  echo -e ">>>> PASSED: isort style check"
fi

if [ "$BLACK_RETVAL" != "0" ]; then
  echo -e "\n\n>>>> FAILED: black style check; begin output\n\n"
  echo -e $(black --check --diff python)
  echo -e "\n\n>>>> FAILED: black style check; end output\n\n"
else
  echo -e ">>>> PASSED: black style check"
fi

if [ "$FLAKE_RETVAL" != "0" ]; then
  echo -e "\n\n>>>> FAILED: flake8 style check; begin output\n\n"
  echo -e "$FLAKE"
  echo -e "\n\n>>>> FAILED: flake8 style check; end output\n\n"
else
  echo -e ">>>> PASSED: flake8 style check"
fi

if [ "$FLAKE_CYTHON_RETVAL" != "0" ]; then
  echo -e "\n\n>>>> FAILED: flake8-cython style check; begin output\n\n"
  echo -e "$FLAKE_CYTHON"
  echo -e "\n\n>>>> FAILED: flake8-cython style check; end output\n\n"
else
  echo -e ">>>> PASSED: flake8-cython style check"
fi

RETVALS=($ISORT_RETVAL $BLACK_RETVAL $FLAKE_RETVAL $FLAKE_CYTHON_RETVAL)
IFS=$'\n'
RETVAL=`echo "${RETVALS[*]}" | sort -nr | head -n1`

exit $RETVAL
