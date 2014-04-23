#!/bin/bash

for ((i=13; i<=62; i++));do

        echo "#---->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#"       >> log.txt
        echo "# CHANNEL=${i}"                                                          >> log.txt
        echo recpt1 --b25 ${i} 60 ${i}.ts                                              >> log.txt
        recpt1 --b25 ${i} 60 ${i}.ts                                                   >> log.txt 2>&1
        echo "#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<----#"       >> log.txt

done

for ((i=13; i<=63; i++));do

        echo "#---->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#"       >> log.txt
        echo "# CHANNEL=C${i}"                                                         >> log.txt
        echo recpt1 --b25 C${i} 60 C${i}.ts                                            >> log.txt
        recpt1 --b25 C${i} 60 C${i}.ts                                                 >> log.txt 2>&1
        echo "#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<----#"       >> log.txt

done
