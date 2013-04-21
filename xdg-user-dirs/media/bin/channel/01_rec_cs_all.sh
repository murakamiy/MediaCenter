#!/bin/bash

for ((i=2; i<=24; i++));do

        echo "#---->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#"       >> log.txt
        echo "# CHANNEL=CS${i}"                                                        >> log.txt
        echo recpt1 --b25 --strip --sid hd CS${i} 120 CS${i}.ts                        >> log.txt
        recpt1 --b25 --strip --sid hd CS${i} 120 CS${i}.ts                             >> log.txt 2>&1
        echo "#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<----#"       >> log.txt

done
