#!/bin/bash
source $(dirname $0)/config

xml=$1
volume_adjust=$2
skip_duration=$3

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

if [ -z "$skip_duration" -o "$skip_duration" = "0" ];then
    seek_param=
else
    seek_param="-ss $skip_duration"
fi

ffmpeg -y $seek_param \
-loglevel error \
-analyzeduration 30M \
-probesize 100M \
-hwaccel cuvid \
-c:v mpeg2_cuvid \
-deint bob \
-resize ${encode_width}x${encode_height} \
-i async:tcp://${ip_addr_recive}:${EN_PORT_NO_GPU_RECIEVE}?listen \
-r 30000/1001 \
-force_key_frames 'expr:gte(t,n_forced*3)' \
-rc constqp \
-qp 34 \
-init_qpP 34 \
-init_qpB 34 \
-init_qpI 34 \
-c:v hevc_nvenc \
$volume_adjust_param -c:a aac \
-f matroska \
tcp://${ip_addr_send}:${EN_PORT_NO_GPU_SEND} > ${EN_DIR_LOG}/gpu/${job_file_xml} 2>&1

if [ $? -eq 0 ];then
    touch ${EN_DIR_LOG}/gpu/${job_file_xml}.success
fi
