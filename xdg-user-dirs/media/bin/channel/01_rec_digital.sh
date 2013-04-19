#!/bin/bash

for ((i=13; i<=62; i++));do

        echo "#---->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#"       >> log.txt
        echo "# CHANNEL=${i}"                                                          >> log.txt
        echo recpt1 --b25 --strip --sid hd ${i} 120 ${i}.ts                            >> log.txt
        recpt1 --b25 --strip --sid hd ${i} 120 ${i}.ts                                 >> log.txt 2>&1
        echo "#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<----#"       >> log.txt

done
