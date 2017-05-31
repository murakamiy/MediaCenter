#!/bin/bash
source $(dirname $0)/config

job_file_xml=$1
width=$2
height=$3

ip_addr_recive=$(nslookup EncodeServer | grep Address: | tail -n 1 | awk '{ print $2 }')
ip_addr_send=$(nslookup MediaCenter | grep Address: | tail -n 1 | awk '{ print $2 }')

nice \
ffmpeg -y \
-loglevel error \
-analyzeduration 30M \
-probesize 100M \
-i async:tcp://${ip_addr_recive}:${EN_PORT_NO_CPU_RECIEVE}?listen \
-vf yadif=mode=0:parity=-1:deint=1,scale=w=${width}:h=${height} \
-preset:v fast \
-crf 28 \
-c:v libx265 \
-c:a aac \
-f matroska \
tcp://${ip_addr_send}:${EN_PORT_NO_CPU_SEND} > ${EN_DIR_LOG}/cpu/${job_file_xml} 2>&1
