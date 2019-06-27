#!/bin/bash

# Run flake8 and get results/return code
FLAKE=`flake8 python`
RETVAL=$?

# Output results if failure otherwise show pass
if [ "$FLAKE" != "" ]; then
  echo -e "\n\n>>>> FAILED: flake8 style check; begin output\n\n" >&2
  echo -e "$FLAKE" >&2
  echo -e "\n\n>>>> FAILED: flake8 style check; end output\n\n" >&2
else
  echo -e "\n\n>>>> PASSED: flake8 style check\n\n"
fi

exit $RETVAL
