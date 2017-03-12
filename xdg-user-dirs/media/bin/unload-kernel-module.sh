#!/bin/bash

for ((i = 1; i <= 5; i++));do
    for m in $(lsmod | sed -ne '2,$p' | awk '{ print $1 }');do
        modprobe -r $m > /dev/null 2>&1
    done
done

lsmod | awk '{ print $1 }'
