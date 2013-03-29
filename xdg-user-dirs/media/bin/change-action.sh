#!/bin/bash
source $(dirname $0)/00.conf

arr=($(/bin/ls $MC_BIN_NAUTILUS_PNG | egrep -v '(action|main)\.sh'))
link=$(basename $(/bin/ls -l ${MC_BIN_NAUTILUS_PNG}/action.sh | awk -F '->' '{ print $2 }'))
arr_size=${#arr[@]}
last_index=$(($arr_size - 1))
index=-1

# echo ${arr[@]}
# echo $arr_size
# echo $last_index

for ((i=0; i<$arr_size; i++));do

    if [ "$link" = "${arr[$i]}" ];then
        index=$i
        echo $link
        break
    fi

done

if [ $index -eq -1 -o $index -eq $last_index ];then
    new_index=0
else
    new_index=$((index + 1))
fi

zenity --warning --no-wrap --timeout=5 --display=:0.0 --text="<span font_desc='40'>${arr[$new_index]}</span>"

ln -sf ${MC_BIN_NAUTILUS_PNG}/${arr[$new_index]} ${MC_BIN_NAUTILUS_PNG}/action.sh
