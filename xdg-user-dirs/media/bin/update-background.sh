#!/bin/bash
source $(dirname $0)/00.conf

job_dir=$MC_DIR_RECORDING
root_dir=$MC_DIR_BACKGROUND
run_dir=${root_dir}/run
job_file=${root_dir}/job.png
font_name=/usr/share/fonts/truetype/takao-gothic/TakaoPGothic.ttf
font_size=68
font_color=black
background_color=darkgray

convert -size 1280x720 xc:$background_color $job_file
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s $job_file
xfdesktop --reload

find $run_dir -type f -delete
touch ${run_dir}/{01,02}

while [ true ];do

    run_file=$(ls -t $run_dir | tail -n 1)
    ls $job_dir > ${run_dir}/${run_file}
    diff -q ${run_dir}/* > /dev/null
    if [ $? -eq 0 ];then
        sleep 60
        continue
    fi

    i=0
    for f in $(find $job_dir -type f -name '*.xml' -not -size 0);do

        epoch=$(xmlsel -t -m "//epoch[@type='stop']" -v '.' $f)
cat << EOF
$epoch	$f
EOF

    done | sort -k 1 -n | tail -n 4 | awk '{ print $2 }' |
    (while read f;do

        title=$(xmlsel -t -m '//title' -v '.' $f | tr -d '[[:punct:]]' | sed -e 's/　/ /g')
        channel=$(xmlsel -t -m '//programme' -v '@channel' $f)
        start=$(xmlsel -t -m "//time[@type='start']" -v '.' $f | awk '{ print substr($2, 1, 5) }')
        stop=$(xmlsel -t -m "//time[@type='stop']" -v '.' $f   | awk '{ print substr($2, 1, 5) }')

        j=$(($i * 2 + 1))
        y1=$((84 * $j))
        y2=$((84 * ($j + 1)))

        echo -n " -draw \"text 60,$y1 '[ $start >> $stop ]  @$channel'\" -draw \"text 60,$y2 '$title'\""

        ((i++))
    done; echo) |
    while read draw_command;do

        eval convert \
        -size 1280x720 xc:$background_color \
        -font $font_name \
        -pointsize $font_size \
        -fill $font_color \
        $draw_command \
        $job_file

    done

    xfdesktop --reload

    sleep 60
done
