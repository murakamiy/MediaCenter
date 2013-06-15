#!/bin/bash 
source $(dirname $0)/00.conf

command=$1

if [ -z "$command" ];then
cat << EOF
USAGE: $(basename $0) command
       command:
                atrm
                mk_title_encode [FILE]...
                mk_title_ts [FILE]...
                ts
                title
                rec
                rsv
EOF
exit
fi

case $command in
    atrm)
        for i in $(atq | awk '{ print $1 }');do atrm $i; done
        ;;
    ts)
        for f in $MC_DIR_JOB_FINISHED/*;do
            title=$(print_title $f)
            start=$(xmlsel -t -m "//epoch[@type='start']" -v '.' $f)
            end=$(xmlsel -t -m "//epoch[@type='stop']" -v '.' $f)
            ((time = (end - start) / 60))
            ts_file=$(ls -sh ${MC_DIR_TS_HD}/$(basename $f .xml).ts)
            echo "$ts_file $time $title"
        done
        ;;
    title)
        for f in $(find $MC_DIR_TITLE_TS -type f);do

            png_file=$f
            inode=$(stat --format='%i' $png_file)
            thumb_file=$(basename $(find $MC_DIR_THUMB -inum $inode))
            base=$(echo $thumb_file | awk -F . '{ print $1 }')
            xml_file=${base}.xml

            title=
            if [ -f $MC_DIR_JOB_FINISHED/$xml_file ];then
                title=$(print_title $MC_DIR_JOB_FINISHED/$xml_file)
            fi

            if [ -f $MC_DIR_TS_HD/$base.ts ];then
                echo "hd  : $(ls -sh $MC_DIR_TS_HD/$base.ts) $title"
            elif [ -f $MC_DIR_TS/$base.ts ];then
                echo "ssd : $(ls -sh $MC_DIR_TS/$base.ts) $title"
            else
                echo "not_exist : $f"
            fi

        done
        ;;
    rec)
        echo MC_DIR_RECORDING
        for f in $(find $MC_DIR_RECORDING -type f);do
            title=$(print_title $f)
            start=$(xmlsel -t -m "//epoch[@type='start']" -v '.' $f)
            end=$(xmlsel -t -m "//epoch[@type='stop']" -v '.' $f)
            ((time = (end - start) / 60))
            ts_file=$(ls -sh ${MC_DIR_TS}/$(basename $f .xml).ts)
            echo "$ts_file $time $title"
        done
        echo RECORD_FINISHED
        for f in $(find $MC_DIR_RECORD_FINISHED -type f);do
            title=$(print_title $f)
            start=$(xmlsel -t -m "//epoch[@type='start']" -v '.' $f)
            end=$(xmlsel -t -m "//epoch[@type='stop']" -v '.' $f)
            ((time = (end - start) / 60))
            ts_file=${MC_DIR_TS}/$(basename $f .xml).ts 
            echo "$ts_file $time $title"
        done
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
    mk_title_ts)
        shift
        for f in $@;do
            job_file_base=$(basename $f .ts)
            job_file_xml=${job_file_base}.xml
            job_file_ts=${job_file_base}.ts
            title=$(print_title ${MC_DIR_JOB_FINISHED}/${job_file_xml})
            category=$(print_category ${MC_DIR_JOB_FINISHED}/${job_file_xml})
            broadcasting=$(xmlsel -t -m '//broadcasting' -v '.' ${MC_DIR_JOB_FINISHED}/${job_file_xml})

            thumb_file=${MC_DIR_THUMB}/${job_file_ts}
            echo "ffmpeg -y -i ${MC_DIR_TS}/${job_file_ts} -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png"
            ffmpeg -y -i ${MC_DIR_TS}/${job_file_ts} -f image2 -pix_fmt yuv420p -vframes 1 -ss 5 -s 320x180 -an -deinterlace ${thumb_file}.png > /dev/null 2>&1
            if [ $? -eq 0 ];then
                mv ${thumb_file}.png $thumb_file
            else
                cp $MC_FILE_THUMB $thumb_file
            fi
            category_dir="${MC_DIR_TITLE_TS}/${category}"
            category_dir="${MC_DIR_TITLE_TS}/${broadcasting}/${category}"
            mkdir -p "$category_dir"
            for i in $(seq -w 1 99);do
                if [ ! -e "${category_dir}/${title}${i}.png" ];then
                    break
                fi
            done
            ln $thumb_file "${category_dir}/${title}${i}.png"

        done
        ;;
    rsv)
        for f in $MC_DIR_RESERVED/*;do
            title=$(print_title $f)
            time=$(xmlsel -t -m "//time[@type='start']" -v '.' $f)
            channel=$(xmlsel -t -m '//programme' -v '@channel' $f)
            echo -e "$time\t$channel\t$title"
        done | column -t -s '	'
        ;;
esac
