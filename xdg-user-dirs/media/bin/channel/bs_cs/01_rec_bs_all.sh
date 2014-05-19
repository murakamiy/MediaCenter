#!/bin/bash

for node in $(seq -w 1 23);do

    for slot in $(seq 0 2);do

        echo "#---->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#"       >> log.txt
        echo "# CHANNEL=BS${node}_${slot}"                                             >> log.txt
        echo "recpt1 --b25 --sid hd BS${node}_${slot} 60 BS${node}_${slot}.ts"         >> log.txt
        recpt1 --b25 --sid hd BS${node}_${slot} 60 BS${node}_${slot}.ts                >> log.txt 2>&1
        echo "#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<----#"       >> log.txt

    done

done
