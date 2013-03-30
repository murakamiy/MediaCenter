#!/bin/bash
source $(dirname $0)/../00.conf

xml=${MC_DIR_JOB_FINISHED}/${5}
title=$(xmlsel -t -m '//title' -v '.' $xml)

killall zenity
zenity --question --display=:0.0 --text="<span font_desc='40'>add to dislike ?\n\n$title</span>"
if [ $? -eq 0 ];then
    /bin/cp -f $xml ${MC_DIR_DISLIKE}/${title}.xml
fi

#   --question                                     質問ダイアログを表示する
#   --text=TEXT                                    ダイアログに表示する文字列を指定する
#   --ok-label=TEXT                                OK ボタンのラベルを指定する
#   --cancel-label=TEXT                            キャンセル・ボタンのラベルを指定する
#   --no-wrap                                      テキストをラッピングしない
