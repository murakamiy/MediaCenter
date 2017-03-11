#!/bin/bash
source $(dirname $0)/config

ip_addr_recive=$(nslookup EncodeServer | grep Address: | tail -n 1 | awk '{ print $2 }')
ip_addr_send=$(nslookup MediaCenter | grep Address: | tail -n 1 | awk '{ print $2 }')

nice \
ffmpeg -y \
-loglevel quiet \
-analyzeduration 30M \
-probesize 100M \
-i async:tcp://${ip_addr_recive}:${EN_PORT_NO_CPU_RECIEVE}?listen \
-vf yadif=mode=0:parity=-1:deint=1,scale=w=1280:h=720 \
-preset:v fast \
-profile:v high \
-level 40 \
-crf 24 \
-c:v libx264 \
-c:a aac \
-f matroska \
tcp://${ip_addr_send}:${EN_PORT_NO_CPU_SEND}
