#!/bin/bash
source $(dirname $0)/config

ip_addr_recive=$(nslookup EncodeServer | grep Address: | tail -n 1 | awk '{ print $2 }')
ip_addr_send=$(nslookup MediaCenter | grep Address: | tail -n 1 | awk '{ print $2 }')

process=0

for ((i = 0; i <= 10; i++));do

    process=0
    for k in $(ps -ef | grep ffmpeg | grep ${ip_addr_recive}:${EN_PORT_NO_CPU_RECIEVE} | awk '{ print $2 }');do
        ((process++))
        kill -TERM $k > /dev/null 2>&1
    done

    if [ $process -eq 0 ];then
        break
    fi

    sleep 6
done

for ((i = 0; i <= 10; i++));do

    process=0
    for k in $(ps -ef | grep ffmpeg | grep ${ip_addr_recive}:${EN_PORT_NO_CPU_RECIEVE} | awk '{ print $2 }');do
        ((process++))
        kill -KILL $k > /dev/null 2>&1
    done

    if [ $process -eq 0 ];then
        break
    fi

    sleep 6
done

if [ $process -eq 0 ];then
    exit 0
else
    exit 1
fi
