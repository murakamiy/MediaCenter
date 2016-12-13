#!/bin/bash
source $(dirname $0)/config

xml=$1
job_file_base=$(basename $xml .xml)
job_file_xml=${job_file_base}.xml
encode_width=$(xmlsel -t -m //encode-width   -v .   ${EN_DIR_XML}/${job_file_xml})
encode_height=$(xmlsel -t -m //encode-height -v .   ${EN_DIR_XML}/${job_file_xml})
encode_bitrate=$(xmlsel -t -m //encode-bitrate -v . ${EN_DIR_XML}/${job_file_xml})
ip_addr_recive=$(getent ahostsv4 EncodeServer | head -n 1 | awk '{ print $1 }')
ip_addr_send=$(getent ahostsv4 MediaCenter | head -n 1 | awk '{ print $1 }')

kill -KILL $(ps -ef | grep ffmpeg | grep ${ip_addr_recive}:${EN_PORT_NO_GPU_RECIEVE} | awk '{ print $2 }') > /dev/null 2>&1

ffmpeg -y \
-loglevel quiet \
-analyzeduration 30M \
-probesize 100M \
-hwaccel cuvid \
-c:v mpeg2_cuvid \
-i async:tcp://${ip_addr_recive}:${EN_PORT_NO_GPU_RECIEVE}?listen \
-vf "scale_npp=w=${encode_width}:h=${encode_height}:interp_algo=super" \
-preset:v 5 \
-profile:v 0 \
-level 30 \
-rc 0 \
-cq 28 \
-c:v h264_nvenc \
-c:a aac \
-f matroska \
tcp://${ip_addr_send}:${EN_PORT_NO_GPU_SEND}
