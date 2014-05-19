#!/bin/bash

for t in *.ts;do

    c=$(basename $t .ts)
    echo $c $t

    python ../../epgdump_py/epgdump.py -e -d -b -i $t -o ${c}.xml

    tmp=$(mktemp)
    xmlstarlet fo --encode utf-8 ${c}.xml > $tmp
    /bin/mv $tmp ${c}.xml

done
