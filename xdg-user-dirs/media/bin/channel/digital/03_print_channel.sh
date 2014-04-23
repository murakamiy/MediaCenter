#!/bin/bash

for x in *.xml;do

    xmlstarlet sel -t -m '//channel' -n -m display-name -v . -o '	' $x |
    awk -F '\t' '{ printf("%s\thd\t%s\t%s\n", $2, $1, $2) }'

done
