#!/bin/bash

for node in $(seq -w 1 23);do

    for slot in $(seq 0 2);do

        echo "#---->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#"
        echo "# CHANNEL=BS${node}_${slot}"
        echo "recpt1 --b25 --sid hd BS${node}_${slot} 5 BS${node}_${slot}.ts"
        recpt1 --b25 --sid hd BS${node}_${slot} 5 BS${node}_${slot}.ts
        echo "#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<----#"

    done

done 2>&1 | tee log.txt


for node in $(seq -w 1 23);do

    for slot in $(seq 0 2);do
        recpt1 --b25 BS${node}_${slot} 60 BS${node}_${slot}.ts
    done

done
