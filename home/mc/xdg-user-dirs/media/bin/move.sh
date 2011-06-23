#!/bin/bash
temp_dir=/home/mc/xdg-user-dirs/picture/mplayer
pict_dir=/home/mc/xdg-user-dirs/picture

i=$(find $pict_dir -name 'move' | wc -l)
((i++))
for f in $(find $pict_dir -name 'shot*');do
    ii=$(printf '%08i' $i)
    mv $f ${pict_dir}/"move$ii.png"
    ((i++))
done

find $temp_dir -name '*.png' -exec mv '{}' $pict_dir \;

for f in $(find $pict_dir -name 'shot*');do
    ii=$(printf '%08i' $i)
    mv $f ${pict_dir}/"move$ii.png"
    ((i++))
done

