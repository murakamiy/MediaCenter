#!/bin/bash
source $(dirname $0)/config

ip_addr_recive=$(nslookup EncodeServer | grep Address: | tail -n 1 | awk '{ print $2 }')
ip_addr_send=$(nslookup MediaCenter | grep Address: | tail -n 1 | awk '{ print $2 }')

kill -KILL $(ps -ef | grep ffmpeg | grep ${ip_addr_recive}:${EN_PORT_NO_GPU_RECIEVE} | awk '{ print $2 }') > /dev/null 2>&1
