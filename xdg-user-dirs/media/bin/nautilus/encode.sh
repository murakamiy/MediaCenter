#!/bin/bash
source $(dirname $0)/../00.conf

xml=${MC_DIR_JOB_FINISHED}/${4}
title=$(xmlsel -t -m '//title' -v '.' $xml)
title=$(echo $title | sed -e 's/[<>]/ /g')

killall zenity
zenity --question --display=:0.0 --text="<span font_desc='36'>add to encode?\n\n$title</span>"
if [ $? -eq 0 ];then

    if [ -f ${MC_DIR_ENCODE_RESERVED}/$(basename ${xml}) ];then
        zenity --warning --timeout=30 --display=:0.0 --text="<span font_desc='40'>encoding already reserved</span>"
        exit
    elif [ -f ${MC_DIR_ENCODE_FINISHED}/$(basename ${xml}) ];then
        zenity --warning --timeout=30 --display=:0.0 --text="<span font_desc='40'>encoding already finished</span>"
        exit
    fi

    /bin/cp -f $xml $MC_DIR_ENCODE_RESERVED
fi

#   --question                                     質問ダイアログを表示する
#   --text=TEXT                                    ダイアログに表示する文字列を指定する
#   --ok-label=TEXT                                OK ボタンのラベルを指定する
#   --cancel-label=TEXT                            キャンセル・ボタンのラベルを指定する
#   --no-wrap                                      テキストをラッピングしない
