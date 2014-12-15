#!/bin/bash

PROGRAM="test.out|clang-3.3|llvm-link"
SLEEP=20

while true; do
ps eaxo bsdtime,pid,comm | egrep $PROGRAM | grep "2:" | awk '{print $2}' | xargs kill -9
sleep $SLEEP
done
