#!/bin/bash

for f in *.xml;do
    xmlstarlet sel -t -m '//channel' -n -m display-name -v . -o '	' $f
done |
awk -F '\t' '{ printf("%s\t%s\n", $2, $1) }' |
sort -k 1 |
awk -F '\t' '
BEGIN {
    prev = ""
}

{
    current = $2
    if (current != prev) {
        sid = $1
        sub("[BC]S_", "", sid)
        printf("%s\t%s\t%s\n", $1, sid, $2)
    }
    prev = $2
}' |
sort -t '	' -k 2 -n
