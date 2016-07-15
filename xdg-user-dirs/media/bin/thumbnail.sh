#!/bin/bash

input=$1
output=$2

ffmpeg \
-y -ss 5 \
-loglevel quiet \
-i $input \
-f image2 \
-vcodec png \
-vframes 2 \
-s 320x180 \
-an -vsync 0 \
-deinterlace \
$output

file $output | grep -q 'PNG image data'
exit $?
