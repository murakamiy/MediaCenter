#!/bin/bash
source $(dirname $0)/config

xml=$1
volume_adjust=$2

job_file_base=$(basename $xml .xml)
job_file_xml=${job_file_base}.xml
encode_width=$(xmlsel -t -m //encode-width   -v .   ${EN_DIR_XML}/${job_file_xml})
encode_height=$(xmlsel -t -m //encode-height -v .   ${EN_DIR_XML}/${job_file_xml})
encode_bitrate=$(xmlsel -t -m //encode-bitrate -v . ${EN_DIR_XML}/${job_file_xml})
ip_addr_recive=$(nslookup EncodeServer | grep Address: | tail -n 1 | awk '{ print $2 }')
ip_addr_send=$(nslookup MediaCenter | grep Address: | tail -n 1 | awk '{ print $2 }')

if [ -z "$volume_adjust" -o "$volume_adjust" = "0" ];then
    volume_adjust_param=
else
    volume_adjust_param="-af volume=${volume_adjust}dB"
fi

ffmpeg -y \
-loglevel warning \
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
-global_quality 28 \
-c:v h264_nvenc \
$volume_adjust_param -c:a aac \
-f matroska \
tcp://${ip_addr_send}:${EN_PORT_NO_GPU_SEND} > ${EN_DIR_LOG}/gpu/${job_file_xml} 2>&1
