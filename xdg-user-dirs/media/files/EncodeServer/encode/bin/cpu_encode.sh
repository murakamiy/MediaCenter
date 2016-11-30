#!/bin/bash
source $(dirname $0)/config

ip_addr_recive=$(getent ahostsv4 EncodeServer | head -n 1 | awk '{ print $1 }')
ip_addr_send=$(getent ahostsv4 MediaCenter | head -n 1 | awk '{ print $1 }')

kill -KILL $(ps -ef | grep ffmpeg | grep ${ip_addr_recive}:${EN_PORT_NO_CPU_RECIEVE} | awk '{ print $2 }') > /dev/null 2>&1

ffmpeg -y \
-loglevel quiet \
-analyzeduration 30M \
-probesize 100M \
-i tcp://${ip_addr_recive}:${EN_PORT_NO_CPU_RECIEVE}?listen \
-threads 3 \
-vf yadif=mode=0:parity=-1:deint=1,scale=w=1280:h=720 \
-preset:v fast \
-profile:v high \
-level 32 \
-crf 24 \
-c:v libx264 \
-c:a aac \
-f matroska \
tcp://${ip_addr_send}:${EN_PORT_NO_CPU_SEND}
