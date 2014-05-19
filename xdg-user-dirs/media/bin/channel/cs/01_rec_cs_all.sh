#!/bin/bash

for ((i=2; i<=24; i++));do

        echo "#---->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#"
        echo "# CHANNEL=CS${i}"
        echo "recpt1 --b25 --sid hd CS${i} 5 CS${i}.ts"
        recpt1 --b25 --sid hd CS${i} 5 CS${i}.ts
        echo "#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<----#"

done 2>&1 | tee log.txt

for ((i=2; i<=24; i++));do

        recpt1 --b25 CS${i} 60 CS${i}.ts

done
