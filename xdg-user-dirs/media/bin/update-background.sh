#!/bin/bash
source $(dirname $0)/00.conf

job_dir=$MC_DIR_RECORDING
root_dir=$MC_DIR_BACKGROUND
run_dir=${root_dir}/run
input_dir=${root_dir}/in
work_dir=${root_dir}/work
job_file=${root_dir}/job.bmp
font_name=/usr/share/fonts/truetype/takao-gothic/TakaoPGothic.ttf
font_size=128
font_color=black
x=220

xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s $job_file

while [ true ];do

    run_file=$(ls -t $run_dir | tail -n 1)
    ls $job_dir > ${run_dir}/${run_file}
    diff -q ${run_dir}/* > /dev/null
    if [ $? -eq 0 ];then
        sleep 60
        continue
    fi

    i=1
    meta_work=$(for f in $(find $job_dir -type f -name '*.xml' -not -size 0);do
        epoch=$(xmlsel -t -m "//epoch[@type='stop']" -v '.' $f)
cat << EOF
$epoch	$f
EOF
    done | sort -k 1 -n | tail -n 4 | awk '{ print $2 }' |
    while read f;do

        if [ $i -eq 1 ];then
            y1=160
            y2=320
        else
            y1=150
            y2=300
        fi

        title=$(xmlsel -t -m '//title' -v '.' $f | tr -d '[[:punct:]]' | sed -e 's/　/ /g')
        channel=$(xmlsel -t -m '//programme' -v '@channel' $f)
        start=$(xmlsel -t -m "//time[@type='start']" -v '.' $f | awk '{ print substr($2, 1, 5) }')
        stop=$(xmlsel -t -m "//time[@type='stop']" -v '.' $f   | awk '{ print substr($2, 1, 5) }')

        convert ${input_dir}/${i}.bmp -font $font_name -pointsize $font_size -fill $font_color \
        -draw "text $x,$y1 '[ $start >> $stop ]  @$channel'" \
        -draw "text $x,$y2 '$title'" \
        ${work_dir}/${i}.bmp

        echo -n $i
        ((i++))
    done)

    meta_in=1234
    meta_in=${meta_in/$meta_work/}
    list_work=
    list_in=
    if [ -n "$meta_in" ];then
        list_in=${input_dir}/[$meta_in].bmp
    fi
    if [ -n "$meta_work" ];then
        list_work=${work_dir}/[$meta_work].bmp
    fi

    convert -append $list_work $list_in $job_file
    xfdesktop --reload

    sleep 60
done
