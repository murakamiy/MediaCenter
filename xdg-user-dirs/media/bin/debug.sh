#!/bin/bash 
source $(dirname $0)/00.conf

command=$1

if [ -z "$command" ];then
cat << EOF
USAGE: $(basename $0) command
       command:
                atrm
                mk_title_encode [FILE]...
                mk_title_encode_mt
                mk_title_ts [FILE]...
                ts
                encode
                rec
                rsv
                cpu [DAYS]
                du  [DAYS]
                find
                inv
                invk
                halt
                abort
EOF
exit
fi

case $command in
    abort)
        touch $MC_ABORT_SHUTDOWN
        echo shutdown cancelled
        ;;
    halt)
        bash $MC_BIN_SAFE_SHUTDOWN
        ;;
    inv)
        bash $($MC_BIN_REALPATH /home/mc/work/invoke.sh) invoke
        ;;
    invk)
        pkill --parent $(ps aux | grep $(dirname $($MC_BIN_REALPATH /home/mc/work/invoke.sh)) | awk '{ printf("%s,", $2) }' | sed -e 's/,$//')
        kill $(ps aux | grep $(dirname $($MC_BIN_REALPATH /home/mc/work/invoke.sh)) | awk '{ print $2 }')
        kill $(ps aux | grep $(dirname $($MC_BIN_REALPATH /home/mc/work/invoke.sh)) | awk '{ print $2 }')
        ;;
    atrm)
        for i in $(atq | grep -v ' = ' | awk '{ print $1 }');do
            atrm $i
        done
        ;;
    ts)
        for f in $(find $MC_DIR_TS $MC_DIR_TS_HD);do
            xml_file=$MC_DIR_JOB_FINISHED/$(basename $f .ts).xml
            if [ ! -f $xml_file ];then
                continue
            fi
            title=$(print_title $xml_file)
            ts_file=$f
            size=$(ls -sh $ts_file | awk '{ print $1 }')
            time=$(xmlsel -t -m "//rec-time" -v '.' $xml_file)
            time=$(( $time / 60 ))
            echo "${time}min $size $title $ts_file"
        done
        ;;
    encode)
        for f in $(find $MC_DIR_ENCODE_HD -type f);do
            base=$(basename $f | awk -F . '{ print $1 }')
            ext=$(basename $f | awk -F . '{ print $2 }')
            size=$(ls -sh $f | awk '{ print $1 }')
            title=$base
            tag=
            if [ "$ext" = "mp4" ];then
                tag=$(mp4info $f | grep Comments: | awk -F ': ' '{ print $2 }')
            fi
            if [ -f "${MC_DIR_ENCODE_FINISHED}/${base}.xml" ];then
                title=$(print_title ${MC_DIR_ENCODE_FINISHED}/${base}.xml)
            elif [ -n "$tag" ];then
                title=$tag
            fi
            echo "$size $title $f"
        done
        ;;
    rec)
        date +"%Y/%m/%d %H:%M:%S"
        echo
        (
        echo RECORDING
        for f in $(find $MC_DIR_RECORDING -type f -not -name mkjob.xml);do
            title=$(print_title $f)
            start=$(xmlsel -t -m "//epoch[@type='start']" -v '.' $f)
            end=$(xmlsel -t -m "//epoch[@type='stop']" -v '.' $f)
            ((time = (end - start) / 60))
            start=$(xmlsel -t -m "//time[@type='start']" -v '.' $f)
            channel=$(xmlsel -t -m '//programme' -v '@channel' $f)
            echo -e "$start\t$time\t$channel\t$title"
        done
        echo ENCODING
        for f in $(find $MC_DIR_ENCODING -type f -not -name mkjob.xml);do
            title=$(print_title $f)
            start=$(xmlsel -t -m "//epoch[@type='start']" -v '.' $f)
            end=$(xmlsel -t -m "//epoch[@type='stop']" -v '.' $f)
            ((time = (end - start) / 60))
            start=$(stat --format=%Z $f | awk '{ print strftime("%Y/%m/%d %H:%M:%S", $1) }')
            channel=$(xmlsel -t -m '//programme' -v '@channel' $f)
            echo -e "$start\t$time\t$channel\t$title"
        done
        ) | column -t -s '	'
        ;;
    mk_title_encode)
        shift
        for f in $@;do
            base=$(basename $f | awk -F . '{ print $1 }')
            ext=$(basename $f | awk -F . '{ print $2 }')

            thumb_file=${MC_DIR_THUMB}/${base}.${ext}
            echo "ffmpeg -y -i $f -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png"
            ffmpeg -y -i $f -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png > /dev/null 2>&1
            if [ $? -eq 0 ];then
                mv ${thumb_file}.png $thumb_file
            else
                cp $MC_FILE_THUMB $thumb_file
            fi
            title=$base
            tag=
            if [ "$ext" = "mp4" ];then
                tag=$(mp4info $f | grep Comments: | awk -F ': ' '{ print $2 }')
            fi
            if [ -f "${MC_DIR_ENCODE_FINISHED}/${base}.xml" ];then
                title=$(print_title ${MC_DIR_ENCODE_FINISHED}/${base}.xml)
                title=${title}_$(echo $base | awk -F '-' '{ printf("%s_%s", $1, $2) }')
            elif [ -n "$tag" ];then
                title=$tag
            fi
            ln -f $thumb_file "${MC_DIR_TITLE_ENCODE}/${title}.png"
            touch -t 200001010000 "${MC_DIR_TITLE_ENCODE}/${title}.png"
        done
        ;;
    mk_title_encode_mt)
        shift
        for f in $(find /mnt/hd/encode_hd/ -type f);do
            base=$(basename $f | awk -F . '{ print $1 }')
            ext=$(basename $f | awk -F . '{ print $2 }')
            if [ "$ext" = "mp4" ];then
                tag=
                tag=$(mp4info $f | grep Comments: | awk -F ': ' '{ print $2 }')
                if [ -n "$tag" ];then
                    link_name=${tag}.${ext}
                else
                    link_name=${base}.${ext}
                fi
            else
                link_name=${base}.${ext}
            fi
            echo ${base}.${ext} $link_name
            ln $f /mnt/hd/title_encode_mt/${link_name}
        done
        ;;
    mk_title_ts)
        shift
        for f in $@;do
            job_file_base=$(basename $f .ts)
            job_file_xml=${job_file_base}.xml
            job_file_ts=${job_file_base}.ts
            title=$(print_title ${MC_DIR_JOB_FINISHED}/${job_file_xml})
            foundby=$(xmlsel -t -m //foundby -v . ${MC_DIR_JOB_FINISHED}/${job_file_xml} | sed -e 's/Finder//')
            echo $job_file_base $title $foundby

            thumb_file=${MC_DIR_THUMB}/${job_file_ts}
            echo "ffmpeg -y -i ${MC_DIR_TS_HD}/${job_file_ts} -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png"
            ffmpeg -y -i ${MC_DIR_TS_HD}/${job_file_ts} -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png > /dev/null 2>&1
            if [ $? -eq 0 ];then
                mv ${thumb_file}.png $thumb_file
            else
                cp $MC_FILE_THUMB $thumb_file
            fi
            foundby_dir="${MC_DIR_TITLE_TS}/${foundby}"
            mkdir -p "$foundby_dir"
            for i in $(seq -w 1 99);do
                if [ ! -e "${foundby_dir}/${title}_${i}.png" ];then
                    break
                fi
            done
            ln $thumb_file "${foundby_dir}/${title}_${i}.png"

        done
        ;;
    rsv)
        for f in $(find $MC_DIR_RESERVED -type f);do
            title=$(print_title $f)
            time=$(xmlsel -t -m "//time[@type='start']" -v '.' $f)
            channel=$(xmlsel -t -m '//programme' -v '@channel' $f)
            echo -e "$time\t$channel\t$title"
        done | sort | column -t -s '	'
        ;;
    cpu)
        day=1
        if [ -n "$2" ];then
            day=$2
        fi
        for log_file in $(find $MC_DIR_LOG -type f -not -name '*.log' | sort | tail -n $day);do
            echo $log_file
            egrep '\+[0-9.]+°C [0-9]+RPM [0-9.]+V lavg=[0-9.]+' $log_file |
            awk '
            {
                for (i = 1; i <= NF; i++) {
                    if (match($i, "°C")) {
                        n = i
                        break
                    }
                }

                printf("%s %s %s %s %s\n", $1, $n, $(n +1), $(n + 2), $(n + 3))
            }'
        done
        ;;
    du)
        day=1
        if [ -n "$2" ];then
            day=$2
        fi
        for log_file in $(find $MC_DIR_LOG -type f -not -name '*.log' | sort | tail -n $day);do
            echo $log_file
            grep 'disk used' $log_file
        done
        ;;
    find)
        prefix_digital=digital
        prefix_bs_cs=bs_cs
        if [ "$MC_RESERVE_SATELLITE" = "true" ];then
            python $MC_BIN_RESERVER "${prefix_digital}_*.xml" "${prefix_bs_cs}_*.xml" DRY_RUN
        else
            python $MC_BIN_RESERVER "${prefix_digital}_*.xml" DRY_RUN
        fi
        ;;
esac
