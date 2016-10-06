#!/bin/bash 
source $(dirname $0)/00.conf

command=$1

if [ -z "$command" ];then
cat << EOF
USAGE: $(basename $0) command
       command:
                atrm
                mk_title_encode
                mk_title_encode_mt
                mk_title_ts
                ts
                encode
                rec
                rsv
                cpu [DAYS]
                du  [DAYS]
                find
                re_schedule
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
            echo "$ts_file ${time}min $size $title"
        done | sort | column -t
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
            echo "$f $size $title"
        done | sort | column -t
        ;;
    rec)
        (
        echo RECORDING
        for f in $(find $MC_DIR_RECORDING -type f -not -name mkjob.xml | sort);do
            title=$(print_title $f)
            time_start=$(xmlsel -t -m "//time[@type='start']" -v '.' $f | awk '{ print $2 }')
            time_stop=$(xmlsel -t -m "//time[@type='stop']" -v '.' $f | awk '{ print $2 }')
            channel=$(xmlsel -t -m '//programme' -v '@channel' $f)
            priority=$(xmlsel -t -m '//priority' -v . $f | awk '{ printf("%3d", $1) }')
            foundby=$(xmlsel -t -m '//foundby' -v . $f | awk '{ print substr($1, 0, 3) }')
            echo -e "$time_start\t$time_stop\t$channel\t$priority\t$foundby\t$title"
        done
        echo ENCODING
        for f in $(find $MC_DIR_ENCODING -type f -not -name mkjob.xml);do
            title=$(print_title $f)
            time_start=$(xmlsel -t -m "//time[@type='start']" -v '.' $f | awk '{ print $2 }')
            time_stop=$(xmlsel -t -m "//time[@type='stop']" -v '.' $f | awk '{ print $2 }')
            channel=$(xmlsel -t -m '//programme' -v '@channel' $f)
            priority=$(xmlsel -t -m '//priority' -v . $f | awk '{ printf("%3d", $1) }')
            foundby=$(xmlsel -t -m '//foundby' -v . $f | awk '{ print substr($1, 0, 3) }')
            echo -e "$time_start\t$time_stop\t$channel\t$priority\t$foundby\t$title"
        done
        ) | column -t -s '	'
        ;;
    mk_title_encode)
        shift
        if [ -n "$1" ];then
            file_list=$1
            total=1
        else
            file_list=$(find $MC_DIR_ENCODE_HD -type f | sort)
            total=$(find $MC_DIR_ENCODE_HD -type f | wc -l)
        fi
        progress=0
        for f in $file_list;do
            base=$(basename $f | awk -F . '{ print $1 }')
            ext=$(basename $f | awk -F . '{ print $2 }')

            thumb_file=${MC_DIR_THUMB}/${base}.${ext}
            bash $MC_BIN_THUMB $f ${thumb_file}.png
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

            printf '%6d / %6d  %s\n' $((++progress)) $total $title
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
        total=$(find $MC_DIR_TS_HD -type f -name '*.ts' | wc -l)
        progress=0
        for f in $(find $MC_DIR_TS_HD -type f -name '*.ts' | sort);do
            job_file_base=$(basename $f .ts)
            job_file_xml=${job_file_base}.xml
            job_file_ts=${job_file_base}.ts
            title=$(print_title ${MC_DIR_JOB_FINISHED}/${job_file_xml})
            foundby=$(xmlsel -t -m //foundby -v . ${MC_DIR_JOB_FINISHED}/${job_file_xml} | sed -e 's/Finder//')

            thumb_file=${MC_DIR_THUMB}/${job_file_ts}
            bash $MC_BIN_THUMB ${MC_DIR_TS_HD}/${job_file_ts} ${thumb_file}.png
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

            printf '%6d / %6d  %s\n' $((++progress)) $total $title
        done
        ;;
    rsv)
        for f in $(find $MC_DIR_RESERVED -type f | sort);do
            title=$(print_title $f)
            time_start=$(xmlsel -t -m "//time[@type='start']" -v '.' $f | awk '{ print $2 }')
            time_stop=$(xmlsel -t -m "//time[@type='stop']" -v '.' $f | awk '{ print $2 }')
            channel=$(xmlsel -t -m '//programme' -v '@channel' $f)
            priority=$(xmlsel -t -m '//priority' -v . $f | awk '{ printf("%3d", $1) }')
            foundby=$(xmlsel -t -m '//foundby' -v . $f | awk '{ print substr($1, 0, 3) }')
            echo -e "$time_start\t$time_stop\t$channel\t$priority\t$foundby\t$title"
        done | column -t -s '	'
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
            python2 $MC_BIN_RESERVER "${prefix_digital}_*.xml" "${prefix_bs_cs}_*.xml" DRY_RUN
        else
            python2 $MC_BIN_RESERVER "${prefix_digital}_*.xml" DRY_RUN
        fi
        ;;
    re_schedule)
        echo "remove current reserve,"
        echo "and create new reserve ?"
        read input

        if [ "$input" = yes ];then

            for i in $(atq | grep -v ' = ' | awk '{ print $1 }');do
                atrm $i
            done
            rm -f $MC_DIR_RESERVED/*.xml

            prefix_digital=digital
            prefix_bs_cs=bs_cs
            if [ "$MC_RESERVE_SATELLITE" = "true" ];then
                python2 $MC_BIN_RESERVER "${prefix_digital}_*.xml" "${prefix_bs_cs}_*.xml" RE_SCHEDULE
            else
                python2 $MC_BIN_RESERVER "${prefix_digital}_*.xml" RE_SCHEDULE
            fi

            for f in $(find $MC_DIR_RESERVED -type f -name '*.xml');do
                temp_file=$(mktemp)
                xmlstarlet format --encode utf-8 $f > $temp_file
                /bin/mv $temp_file $f
            done
        fi
        ;;
esac
