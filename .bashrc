#####################################################################################################
# Environmental variables
#####################################################################################################
PS1="[\u \W]\\$ "
PATH=$PATH:/home/mc/xdg-user-dirs/media/ubin
# LANG=ja_JP.SJIS
# LANG=ja_JP.eucJP
LANG=ja_JP.utf8
# LANG=C
PAGER='less -MQXcgi -x4'
EDITOR='vim'
HISTSIZE=2000
HISTFILESIZE=2000
HISTCONTROL=ignoredups
HISTIGNORE=ls:ll:la:cd:bg:fg
export PATH PS1 PAGER EDITOR LANG HISTSIZE HISTFILESIZE HISTCONTROL HISTIGNORE
source /etc/bash_completion
#####################################################################################################
# Alias
#####################################################################################################
alias ls='ls -F'
alias la='ls -a'
alias ll='ls -l'
alias lt='ls -lt | head -n 30'
alias lsdir="find ./ -maxdepth 1 -type d -exec basename '{}' \; | sed -e '1d' | column"
alias lsdot='ls -A | grep ^\\.'
alias ..='cd ..'
alias ...='cd ../..'
alias mv='mv -i'
alias cp='cp -i'
alias rm='rm -i'
alias zip='zip -q'
alias unzip='unzip -qo'
alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'
alias info='info --vi-keys'
alias free='free -m'
alias less='less -MQSXcgi -x4'
alias bc='bc -q'
alias psa='ps --headers --sort=pid -e -o %cpu,%mem,rss,ppid,pgrp,pid,user,args'
alias psp='ps --headers --sort=pid -e -o user,args'
alias psm='ps --headers --sort=pid -a -o %cpu,%mem,rss,ppid,pgrp,pid,user,args'
alias getclip='xclip -o'
alias putclip='xclip -i'
alias vimemo='vi ~/work/memo.txt'

alias xml='xmlstarlet'
alias myindent='indent -kr --no-tabs --line-length 100'

alias nkfeuc='nkf -e -Lu -d --overwrite'
alias nkfutf='nkf -w -Lu -d --overwrite'
alias nkfjis='nkf -j -Lw -d --overwrite'
alias nkfsjis='nkf -s -Lw -d --overwrite'

alias cdbin='cd /home/mc/xdg-user-dirs/media/bin'
alias cdubin='cd /home/mc/xdg-user-dirs/media/ubin'
alias cdjob='cd /home/mc/xdg-user-dirs/media/job'
alias cdvideo='cd /home/mc/xdg-user-dirs/media/video'
alias cdfile='cd /home/mc/xdg-user-dirs/media/files'
#####################################################################################################
# Function
#####################################################################################################
function m() {
    mount | grep ^/ | sort
}
function vip() {
    vi -p $(find $@ -type f)
}
function vio() {
    vi -o $@
}
function nautilus() {
    /usr/bin/nautilus $@ > /dev/null 2>&1 &
}
function kakasi-hiragana() {
    echo "$@" | nkfeuc | kakasi -i euc -JH | nkfutf 
}
function kakasi-roman() {
    echo "$@" | nkfeuc | kakasi -i euc -Jaj | nkfutf 
}
function kakasi-katakana() {
    echo "$@" | nkfeuc | kakasi -i euc -JK | nkfutf 
}
function xmlformat() {
    tmp=$(mktemp)
    xml fo --encode utf-8 $1 > $tmp
    /bin/mv -f $tmp $1
}
function xmldelcomment() {
    xml ed -d '//comment()' $1
}
function md() {
    bash /home/mc/xdg-user-dirs/media/bin/debug.sh $@
}
function vinfom() {
    if [ -z "$1" ];then
        mplayer dvd:////dev/sr0 -vo null -ao null -frames 0 -v 2>&1 | egrep '([as]id|VIDEO: |AUDIO: |Selected audio codec: | Track ID )'
    else
        mplayer -vo null -ao null -frames 0 -v "$1" 2>&1 | egrep '(VIDEO: |AUDIO: |Selected audio codec: | Track ID )'
    fi
}
function vinfof() {
    ffmpeg -i "$1" 2>&1 | egrep 'Stream #' | grep -v ': Data: ' | sed -e 's/  */ /' -e 's/^ Stream //'
}
function vinfog() {
    video_id=$(ffmpeg -i $1 2>&1 | grep 'Video:' | grep mpeg2video | tail -n 1 | awk -F '[' '{ print $1 }' | awk -F '#' '{ print $2 }')
    audio_id=$(ffmpeg -i $1 2>&1 | grep 'Audio:' | awk -F ',' '{ print $5" "$1 }' | sort -n -k 1 | tail -n 1 | awk -F '[' '{ print $1 }' | awk -F '#' '{ print $2 }')
    echo -e "video=$video_id\naudio=$audio_id"
}
function vinfoh() {
    video_id=$(ffmpeg -i $1 2>&1 | grep 'Video:' | grep h264 | tail -n 1 | awk -F '[' '{ print $1 }' | awk -F '#' '{ print $2 }')
    audio_id=$(ffmpeg -i $1 2>&1 | grep 'Audio:' | awk -F ',' '{ print $5" "$1 }' | sort -n -k 1 | head -n 1 | awk -F '[' '{ print $1 }' | awk -F '#' '{ print $2 }')
    echo -e "video=$video_id\naudio=$audio_id"
}
function epgdumpy() {
    python /home/mc/xdg-user-dirs/media/bin/epgdump_py/epgdump.py $@
}
function seltime() {
    xmlstarlet sel --encode utf-8 -t -m '//programme' -v '@start' -n $@ |
    python -c '
import datetime
import sys
for line in sys.stdin:
    str = line.split()
    if str:
        print datetime.datetime.strptime(str[0], "%Y%m%d%H%M%S")'
}
function selanime() {
    xmlstarlet sel --encode utf-8 -t -m "//programme" \
        -m "category[contains(., 'アニメ')]" \
        -v 'normalize-space(../title)' -o '  ' -v '../@start' -n $@
}
function selactor() {
    xmlstarlet sel --encode utf-8 -t -m "//programme" \
        -m "desc[contains(., '$1')]" \
        -v 'normalize-space(../title)' -o '  ' -v '../@start' -n $2
}
function smbaterm() {
    smbclient -A ~/.smbauth '//ATERM-CE6499/Samsung-1'
}
