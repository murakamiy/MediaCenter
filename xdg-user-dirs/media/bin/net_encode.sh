#!/bin/bash
source $(dirname $0)/00.conf

function router_wakeup() {
(
    retcode=1
    router_addr=$(ip route | grep ^default | awk '{ print $3 }')

    if [ -n "$router_addr" ];then
        ping -w 1 -qc 1 $router_addr > /dev/null 2>&1
        if [ $? -eq 0 ];then
            retcode=0
        fi
    fi

    if [ $retcode -ne 0 ];then

        python $MC_BIN_BLUETOOTH_WAKEUP
        sleep 10
        for ((i = 1; i <= 20; i++));do

            router_addr=$(ip route | grep ^default | awk '{ print $3 }')
            if [ -n "$router_addr" ];then
                ping -w 1 -qc 1 $router_addr > /dev/null 2>&1
                if [ $? -eq 0 ];then
                    retcode=0
                    break
                fi
            fi
            sleep 2
        done
    fi

    return $retcode
)
}

function try_gpu_encode() {
(
    retry=$1
    ip_addr_recive=$2
    ip_addr_send=$3
    job_file_mkv_abs=$4
    job_file_xml=$5
    input_ts_file=$6
    volume_adjust=$7
    skip_duration=$8
    estimated_time=$9

    if [ "$retry" = "yes" ];then
        gpu_encode_sh=gpu_encode_no_hwaccel.sh
    else
        gpu_encode_sh=gpu_encode.sh
    fi

    ssh en@EncodeServer "bash ${EN_DIR_BIN}/kill_gpu_encoder.sh"
    if [ $? -eq 1 ];then
        return 2
    fi

    ffmpeg -y -loglevel quiet -i async:tcp://${ip_addr_recive}:${MC_PORT_NO_GPU_RECIEVE}?listen -vcodec copy -acodec copy -f matroska $job_file_mkv_abs &
    pid_ffmpeg_recieve=$!
    sleep 1

    ssh en@EncodeServer "echo exec bash ${EN_DIR_BIN}/${gpu_encode_sh} $job_file_xml $volume_adjust $skip_duration | at -M now"
    sleep 1

    gst-launch-1.0 -q \
      filesrc \
      location=${input_ts_file} \
      blocksize=499712000 \
    ! queue \
      silent=true \
      max-size-buffers=1 \
      max-size-bytes=0 \
      max-size-time=0 \
    ! tcpclientsink \
      host=${ip_addr_send} \
      port=${MC_PORT_NO_GPU_SEND} \
      blocksize=4096000 &
    pid_ffmpeg_send=$!

    (
        sleep $estimated_time
        kill -KILL $pid_ffmpeg_send > /dev/null 2>&1
        kill -KILL $pid_ffmpeg_recieve > /dev/null 2>&1
    ) &

    wait $pid_ffmpeg_send
    wait $pid_ffmpeg_recieve

    encode_stat=$(ssh en@EncodeServer "if [ -f ${EN_DIR_LOG}/gpu/${job_file_xml}.success ];then echo success; fi")
    if [ "$encode_stat" = "success" ];then
        return_code=0
    else
        return_code=1
    fi

    return $return_code
)
}

function gpu_encode() {
(
    time_limit=$1

    ip_addr_recive=$(nslookup MediaCenter | grep Address: | tail -n 1 | awk '{ print $2 }')
    ip_addr_send=$(nslookup EncodeServer | grep Address: | tail -n 1 | awk '{ print $2 }')
    rectime_max=$((60 * 60 * 6))
    count=0

    for xml in $(find $MC_DIR_DOWNSIZE_ENCODE_RESERVED -type f -name '*.xml' | sort);do

        job_file_base=$(basename $xml .xml)
        job_file_xml=${job_file_base}.xml
        job_file_ts=${job_file_base}.ts
        job_file_mkv=${job_file_base}.mkv
        job_file_mkv_abs=${MC_DIR_ENCODE_DOWNSIZE}/${job_file_mkv}
        input_ts_file=${MC_DIR_TS}/${job_file_ts}
        duration=$(ffprobe -show_format $input_ts_file 2> /dev/null | grep ^duration= | awk -F = '{ printf("%d\n", $2) }')
        title=$(print_title                                         ${MC_DIR_DOWNSIZE_ENCODE_RESERVED}/${job_file_xml})
        original_file=$(xmlsel -t -m //original-file -v .           ${MC_DIR_DOWNSIZE_ENCODE_RESERVED}/${job_file_xml})
        rec_time=$(xmlsel -t -m //rec-time -v .                     ${MC_DIR_DOWNSIZE_ENCODE_RESERVED}/${job_file_xml})
        foundby=$(xmlsel -t -m //foundby -v .                       ${MC_DIR_DOWNSIZE_ENCODE_RESERVED}/${job_file_xml} | sed -e 's/Finder//')
        filename_web=${title}_$(date +%m%d).mkv

        if [ -f ${MC_DIR_VOLUME_INFO}/${job_file_ts} -a -f ${MC_DIR_FRAME_INFO}/${job_file_ts} ];then
            volume_adjust=$(cat ${MC_DIR_VOLUME_INFO}/${job_file_ts})
            frame_count=$(cat ${MC_DIR_FRAME_INFO}/${job_file_ts} | wc -l)
            skip_duration=10
            if [ $frame_count -lt 300 ];then
                skip_duration=30
            fi
        else
            continue
        fi

        if [ -z "$duration" ];then
            /bin/mv ${MC_DIR_DOWNSIZE_ENCODE_RESERVED}/${job_file_xml} $MC_DIR_FAILED
            log "gpu_encode failed: $title $(hard_ware_info)"
            /bin/mv $xml $MC_DIR_FAILED
            continue
        fi

        if [ $duration -gt $rectime_max ];then
            duration=$rectime_max
        fi
        time_start=$(awk 'BEGIN { print systime() }')
        estimated_time=$(( duration / 16 * 1 ))
        estimated_time_epoch=$(( time_start + estimated_time ))
        if [ $count -gt 0 -a $estimated_time_epoch -gt $time_limit ];then
            log "gpu_encode exceed time limit"
            break
        fi

        scp $xml en@EncodeServer:${EN_DIR_XML}
        ssh en@EncodeServer "ls ${EN_DIR_XML}/${job_file_xml}"
        if [ $? -ne 0 ];then
            log "gpu_encode failed: scp $job_file_xml $title $(hard_ware_info)"
            break
        fi

        ssh en@EncodeServer "bash ${EN_DIR_BIN}/nvinit.sh"
        if [ $? -ne 0 ];then
            log "gpu_encode failed: nvinit $job_file_xml $title $(hard_ware_info)"
            break
        fi

        /bin/mv $xml $MC_DIR_ENCODING_GPU

        retry=no
        try_gpu_encode $retry $ip_addr_recive $ip_addr_send $job_file_mkv_abs $job_file_xml $input_ts_file $volume_adjust $skip_duration $estimated_time
        if [ $? -eq 1 ];then
            estimated_time=$(( duration / 8 * 1 ))
            retry=yes
            try_gpu_encode $retry $ip_addr_recive $ip_addr_send $job_file_mkv_abs $job_file_xml $input_ts_file $volume_adjust $skip_duration $estimated_time
        elif [ $? -eq 2 ];then
            log "gpu_encode failed: kill $job_file_xml $title $(hard_ware_info)"
            /bin/mv ${MC_DIR_ENCODING_GPU}/${job_file_xml} $MC_DIR_FAILED
            break
        fi

        duration=0
        ffprobe -show_format $job_file_mkv_abs > /dev/null 2>&1
        if [ $? -eq 0 ];then
            duration=$(ffprobe -show_format $job_file_mkv_abs 2> /dev/null | grep ^duration= | awk -F = '{ printf("%d\n", $2) }')
        fi
        integrity=$(($rec_time - $duration))
        if [ "$integrity" -lt 180 ];then
            if [ "$original_file" = "release" ];then
                /bin/rm $input_ts_file
                mv -f ${MC_DIR_THUMB}/${job_file_ts} ${MC_DIR_THUMB}/${job_file_mkv}
            fi

            mkvpropedit $job_file_mkv_abs --attachment-name record_description --add-attachment ${MC_DIR_ENCODING_GPU}/${job_file_xml}
            mkdir -p ${MC_DIR_WEBDAV_CONTENTS}/${foundby}
            ln $job_file_mkv_abs "${MC_DIR_WEBDAV_CONTENTS}/${foundby}/${filename_web}"

            /bin/rm ${MC_DIR_ENCODING_GPU}/${job_file_xml}

            time_end=$(awk 'BEGIN { print systime() }')
            (( took = (time_end - time_start) ))
            size=$(ls -sh $job_file_mkv_abs | awk '{ print $1 }')
            log "gpu_encode end: retry=$retry $took sec $size $title $(hard_ware_info)"
        else
            log "gpu_encode failed: retry=$retry $job_file_xml $title $(hard_ware_info)"
            /bin/mv ${MC_DIR_ENCODING_GPU}/${job_file_xml} $MC_DIR_FAILED
        fi

        vmtouch -q -e $job_file_mkv_abs
        vmtouch -q -e $input_ts_file

        ((count++))
    done
)
}

function cpu_encode() {
(
    time_limit=$1

    ip_addr_recive=$(nslookup MediaCenter | grep Address: | tail -n 1 | awk '{ print $2 }')
    ip_addr_send=$(nslookup EncodeServer | grep Address: | tail -n 1 | awk '{ print $2 }')
    rectime_max=$((60 * 60 * 6))
    count=0

    for xml in $(find $MC_DIR_ENCODE_RESERVED -type f -name '*.xml' | sort);do

        job_file_base=$(basename $xml .xml)
        job_file_xml=${job_file_base}.xml
        job_file_ts=${job_file_base}.ts
        job_file_mkv=${job_file_base}.mkv
        job_file_mkv_abs=${MC_DIR_ENCODE}/${job_file_mkv}
        input_ts_file=${MC_DIR_TS}/${job_file_ts}
        duration=$(ffprobe -show_format $input_ts_file 2> /dev/null | grep ^duration= | awk -F = '{ printf("%d\n", $2) }')
        title=$(print_title                                         ${MC_DIR_ENCODE_RESERVED}/${job_file_xml})
        rec_time=$(xmlsel -t -m //rec-time -v .                     ${MC_DIR_ENCODE_RESERVED}/${job_file_xml})

        if [ -z "$duration" ];then
            /bin/mv ${MC_DIR_ENCODE_RESERVED}/${job_file_xml} $MC_DIR_FAILED
            log "cpu_encode failed: $title $(hard_ware_info)"
            continue
        fi

        if [ $duration -gt $rectime_max ];then
            duration=$rectime_max
        fi
        time_start=$(awk 'BEGIN { print systime() }')
        estimated_time=$(( duration / 5 * 4 ))
        estimated_time_epoch=$(( time_start + estimated_time ))
        if [ $count -gt 0 -a $estimated_time_epoch -gt $time_limit ];then
            log "cpu_encode exceed time limit"
            break
        fi

        ssh en@EncodeServer "bash ${EN_DIR_BIN}/kill_cpu_encoder.sh"
        if [ $? -eq 1 ];then
            log "cpu_encode failed: kill $job_file_xml $title $(hard_ware_info)"
            break
        fi

        /bin/mv $xml $MC_DIR_ENCODING_CPU

        ffmpeg -y -loglevel quiet -i async:tcp://${ip_addr_recive}:${MC_PORT_NO_CPU_RECIEVE}?listen -vcodec copy -acodec copy -f matroska $job_file_mkv_abs &
        pid_ffmpeg_recieve=$!
        sleep 1

        ssh en@${ip_addr_send} "echo exec bash ${EN_DIR_BIN}/cpu_encode.sh $job_file_xml 1280 720 | at -M now"
        sleep 1

        gst-launch-1.0 -q \
          filesrc \
          location=${input_ts_file} \
          blocksize=98304000 \
        ! queue \
          silent=true \
          max-size-buffers=1 \
          max-size-bytes=0 \
          max-size-time=0 \
        ! tcpclientsink \
          host=${ip_addr_send} \
          port=${MC_PORT_NO_CPU_SEND} \
          blocksize=4096000 &
        pid_ffmpeg_send=$!

        (
            sleep $estimated_time
            kill -KILL $pid_ffmpeg_send > /dev/null 2>&1
            kill -KILL $pid_ffmpeg_recieve > /dev/null 2>&1
        ) &

        wait $pid_ffmpeg_send
        wait $pid_ffmpeg_recieve

        duration=0
        ffprobe -show_format $job_file_mkv_abs > /dev/null 2>&1
        if [ $? -eq 0 ];then
            duration=$(ffprobe -show_format $job_file_mkv_abs 2> /dev/null | grep ^duration= | awk -F = '{ printf("%d\n", $2) }')
        fi
        integrity=$(($rec_time - $duration))
        if [ "$integrity" -lt 180 ];then

            mkvpropedit $job_file_mkv_abs --attachment-name record_description --add-attachment ${MC_DIR_ENCODING_CPU}/${job_file_xml}
            /bin/mv ${MC_DIR_ENCODING_CPU}/${job_file_xml} $MC_DIR_ENCODE_FINISHED

            time_end=$(awk 'BEGIN { print systime() }')
            (( took = (time_end - time_start) ))
            size=$(ls -sh $job_file_mkv_abs | awk '{ print $1 }')
            log "cpu_encode end: $took sec $size $title $(hard_ware_info)"
        else
            log "cpu_encode failed: $job_file_xml $title $(hard_ware_info)"
            /bin/mv ${MC_DIR_ENCODING_CPU}/${job_file_xml} $MC_DIR_FAILED
        fi

        vmtouch -q -e $job_file_mkv_abs
        vmtouch -q -e $input_ts_file

        ((count++))
    done
)
}

log "start_encode"

time_limit=$1
if [ -z "$time_limit" ];then
    echo "$0 TIME_LIMIT_EPOCH"
    exit
fi

router_wakeup
if [ $? -ne 0 ];then
    log "router wakeup failed"
    exit
fi

wol $(cat ~/.mac_address)
wake=false
for ((i = 0; i < 20; i++));do
    sleep 3
    ssh -o ConnectTimeout=1 en@EncodeServer ls > /dev/null 2>&1
    if [ $? -eq 0 ];then
        wake=true
        break
    fi
done

if [ "$wake" = "false" ];then
    log "encode server wakeup failed"
    exit
fi

sleep 10
ssh en@EncodeServer "bash ${EN_DIR_BIN}/init.sh"

gpu_encode $time_limit &
pid_gpu_encode=$!

cpu_encode $time_limit &
pid_cpu_encode=$!

wait $pid_gpu_encode
wait $pid_cpu_encode

ssh en@EncodeServer "bash ${EN_DIR_BIN}/nvinit.sh"
ssh en@EncodeServer "echo exec bash ${EN_DIR_BIN}/shutdown.sh | at -M now"
bash $MC_BIN_SAFE_SHUTDOWN

log "end_encode"
