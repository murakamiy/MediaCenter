#!/bin/bash 
source $(dirname $0)/00.conf

command=$1

if [ -z "$command" ];then
cat << EOF
USAGE: $(basename $0) command
       command:
                atrm
                do_job
                wutime
                mk_title_encode [FILE]...
                mk_title_ts [FILE]...
                show_ts
                show_video
                show_encode
                show_info
                show_xml
                show_fail
                show_title
                show_reserve
EOF
exit
fi

case $command in
    atrm)
        for i in $(atq | awk '{ print $1 }');do atrm $i; done
        ;;
    do_job)
        for f in $(find ../job/state/01_reserved/ -type f);do bash do_job.sh $f; done
        ;;
    wutime)
        for i in $(awk 'BEGIN { now = systime(); print now; print now + 60 * 10; print now + 60 * 11; for (i=1; i<=24; i++) { print now + 60 * 60 * i; } }');do
            python wakeuptime.py $i
        done
        ;;
    show_xml)
        for f in $MC_DIR_JOB_FINISHED/*;do
            title=$(print_title $f)
            start=$(xmlsel -t -m "//epoch[@type='start']" -v '.' $f)
            end=$(xmlsel -t -m "//epoch[@type='stop']" -v '.' $f)
            ((time = (end - start) / 60))
            echo "$title $f $time"
        done
        ;;
    show_info)
        for f in $MC_DIR_JOB_FINISHED/*;do
            title=$(print_title $f)
            foundby=$(xmlsel -t -m '//foundby' -v '.' $f)
            priority=$(xmlsel -t -m '//priority' -v '.' $f)
            start_date=$(xmlsel -t -m "//time[@type='start']" -v '.' $f | awk '{ print $1 }')
            printf "%s %3d %s %s\n" "$start_date" "$priority" "$foundby" "$title"
        done
        ;;
    show_ts)
        for f in $MC_DIR_JOB_FINISHED/*;do
            title=$(print_title $f)
            start=$(xmlsel -t -m "//epoch[@type='start']" -v '.' $f)
            end=$(xmlsel -t -m "//epoch[@type='stop']" -v '.' $f)
            ((time = (end - start) / 60))
            ts_file=${MC_DIR_TS}/$(basename $f .xml).ts 
            echo "$ts_file $time $title"
        done
        ;;
    show_video)
        for f in $MC_DIR_JOB_FINISHED/*;do
            title=$(print_title $f)
            ts_file=${MC_DIR_TS}/$(basename $f .xml).ts 
            size=$(ls -sh $ts_file | awk '{ print $1 }')
            echo "$title  $size  $ts_file"
            mplayer -vo null -ao null -frames 0 -v $ts_file 2>&1 | egrep '(VIDEO: |AUDIO: |Selected audio codec: )'
            echo
        done
        ;;
    show_encode)
        for encode_file in $MC_DIR_ENCODE/*;do
            name=$(basename $encode_file | awk -F . '{print $1}')
            thumb=$(find $MC_DIR_THUMB -name $name)
            if [ -f "$thumb" ];then
                inode=$(stat --format='%i' $thumb)
                png_file=$(find $MC_DIR_TITLE_ENCODE -inum $inode)
                if [ -f "$png_file" ];then
                    echo "$(basename $png_file .png)"
                fi
            fi
            size=$(ls -sh $encode_file | awk '{print $1}')
            echo "$(basename $encode_file) $size"
            mplayer -vo null -ao null -frames 0 -v $encode_file 2>&1 | egrep '(VIDEO: |AUDIO: |Selected audio codec: )'
            echo
        done
        ;;
    show_fail)
        for f in $MC_DIR_FAILED/*;do
            title=$(print_title $f)
            date=$(xmlsel -t -m "//time[@type='start']" -v '.' $f | awk '{ print $1 }')
            echo "$date $title"
        done
        ;;
    mk_title_encode)
        shift
        for f in $@;do
            base=$(basename $f | awk -F . '{ print $1 }')
            thumb_file=$(basename $f)
            echo $base
            ffmpeg -i $f -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${MC_DIR_THUMB}/${thumb_file}.png > /dev/null 2>&1
            mv "${MC_DIR_THUMB}/${thumb_file}.png" "${MC_DIR_THUMB}/${thumb_file}"
            title=$base
            if [ -f "${MC_DIR_ENCODE_FINISHED}/${base}.xml" ];then
                title=$(print_title ${MC_DIR_ENCODE_FINISHED}/${base}.xml)
                title=${title}_$(echo $base | awk -F '-' '{ printf("%s_%s", $1, $2) }')
            fi
            ln -f "${MC_DIR_THUMB}/${thumb_file}" "${MC_DIR_TITLE_ENCODE}/${title}.png"
            touch -t 200001010000 "${MC_DIR_TITLE_ENCODE}/${title}.png"
        done
        ;;
    mk_title_ts)
        shift
        for f in $@;do
            job_file_base=$(basename $f .ts)
            job_file_xml=${job_file_base}.xml
            job_file_ts=${job_file_base}.ts
            title=$(print_title ${MC_DIR_JOB_FINISHED}/${job_file_xml})
            category=$(print_category ${MC_DIR_JOB_FINISHED}/${job_file_xml})

            thumb_file=${MC_DIR_THUMB}/${job_file_ts}
            echo "ffmpeg -i ${MC_DIR_TS}/${job_file_ts} -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png"
            ffmpeg -i ${MC_DIR_TS}/${job_file_ts} -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png > /dev/null 2>&1
            if [ $? -eq 0 ];then
                mv ${thumb_file}.png $thumb_file
            else
                cp $MC_FILE_THUMB $thumb_file
            fi
            category_dir="${MC_DIR_TITLE_TS}/${category}"
            mkdir -p "$category_dir"
            for i in $(seq -w 1 99);do
                if [ ! -e "${category_dir}/${title}${i}.png" ];then
                    break
                fi
            done
            ln $thumb_file "${category_dir}/${title}${i}.png"

        done
        ;;
    show_title)
        for png_file in $MC_DIR_TITLE_TS/*;do
            inode=$(stat --format='%i' $png_file)
            ts_file=$(basename $(find $MC_DIR_THUMB -inum $inode))
            echo "$(basename $png_file .png) ${MC_DIR_TS}/${ts_file}"
        done
        ;;
    show_reserve)
        for f in $MC_DIR_RESERVED/*;do
            title=$(print_title $f)
            time=$(xmlsel -t -m "//time[@type='start']" -v '.' $f)
            channel=$(xmlsel -t -m '//programme' -v '@channel' $f)
            echo -e "$time\t$channel\t$title"
        done | column -t -s '	'
        ;;
esac
