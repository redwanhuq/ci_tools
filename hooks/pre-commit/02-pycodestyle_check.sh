#!/bin/bash
# This is a pre-commit hook that will warn if any .py file in a commit fails to meet
# PEP8 standards for code style. Note that a commit containing violations will not be
# rejected.

# Iterate over all files in staging area
for file in `git diff --staged --name-status | sed -e '/^D/ d; /^D/! s/.\s\+//'`
do
    # Check whether .py files meet PEP8 standards using pycodestyle linter
    if [[ $file == *py ]]
    then
        OUTPUT=$(pycodestyle --max-line-length=88 -q $file)
        if [ ! -z "$OUTPUT" ]
        then
            echo "WARNING: $file does not meet PEP8 standards for code style"
            echo "View errors by entering: pycodestyle --max-line-length=88 $file"
            echo
        fi
    fi
done
exit 0