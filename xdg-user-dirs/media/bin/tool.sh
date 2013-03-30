#!/bin/bash
source $(dirname $0)/00.conf

while getopts 'abmvdfe' opt;do
    case $opt in
        a)
            ln -sf ${MC_BIN_NAUTILUS_PNG}/mplayer_dts_ac3.sh ${MC_BIN_NAUTILUS_PNG}/action.sh
            killall zenity
            zenity --warning --no-wrap --timeout=10 --display=:0.0 --text="<span font_desc='40'>action changed:\nmplayer AC3,DTS</span>"
            ;;
        b)
            ln -sf ${MC_BIN_NAUTILUS_PNG}/b25.sh ${MC_BIN_NAUTILUS_PNG}/action.sh
            killall zenity
            zenity --warning --no-wrap --timeout=10 --display=:0.0 --text="<span font_desc='40'>action changed:\nb25</span>"
            ;;
        m)
            ln -sf ${MC_BIN_NAUTILUS_PNG}/mplayer.sh ${MC_BIN_NAUTILUS_PNG}/action.sh
            killall zenity
            zenity --warning --no-wrap --timeout=10 --display=:0.0 --text="<span font_desc='40'>action changed:\nmplayer</span>"
            ;;
        v)
            ln -sf ${MC_BIN_NAUTILUS_PNG}/vlc.sh ${MC_BIN_NAUTILUS_PNG}/action.sh
            killall zenity
            zenity --warning --no-wrap --timeout=10 --display=:0.0 --text="<span font_desc='40'>action changed:\nvlc</span>"
            ;;
        d)
            ln -sf ${MC_BIN_NAUTILUS_PNG}/dislike.sh ${MC_BIN_NAUTILUS_PNG}/action.sh
            killall zenity
            zenity --warning --no-wrap --timeout=10 --display=:0.0 --text="<span font_desc='40'>action changed:\ndislike</span>"
            ;;
        f)
            ln -sf ${MC_BIN_NAUTILUS_PNG}/favorite.sh ${MC_BIN_NAUTILUS_PNG}/action.sh
            killall zenity
            zenity --warning --no-wrap --timeout=10 --display=:0.0 --text="<span font_desc='40'>action changed:\nfavorite</span>"
            ;;
        e)
            ln -sf ${MC_BIN_NAUTILUS_PNG}/encode.sh ${MC_BIN_NAUTILUS_PNG}/action.sh
            killall zenity
            zenity --warning --no-wrap --timeout=10 --display=:0.0 --text="<span font_desc='40'>action changed:\nencode</span>"
            ;;
    esac
done
