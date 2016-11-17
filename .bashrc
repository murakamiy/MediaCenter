#####################################################################################################
# Environmental variables
#####################################################################################################
PS1="[\u \W]\\$ "
PATH=$PATH:/home/mc/xdg-user-dirs/media/ubin
# LANG=ja_JP.SJIS
# LANG=ja_JP.eucJP
LANG=ja_JP.utf8
# LANG=C
LC_CTYPE="$LANG"
LC_NUMERIC="$LANG"
LC_TIME="C"
LC_COLLATE="$LANG"
LC_MONETARY="$LANG"
LC_MESSAGES="C"
LC_ALL=
PAGER='less -MQXcgi -x4'
EDITOR='vim'
HISTSIZE=2000
HISTFILESIZE=2000
HISTCONTROL=ignoredups
HISTIGNORE=ls:ll:la:cd:bg:fg
export PATH PS1 PAGER EDITOR LANG HISTSIZE HISTFILESIZE HISTCONTROL HISTIGNORE
export LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES LC_ALL
source /usr/share/bash-completion/bash_completion
#####################################################################################################
# Alias
#####################################################################################################
alias vi='vim'
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
alias scr='screen -r'
#####################################################################################################
# Function
#####################################################################################################
function vlog() {
    view $(find /home/mc/xdg-user-dirs/media/job/log/ -type f -not -name '*.log' -not -name '*.error' | sort | tail -n 1)
}
function vlogy() {
    view $(find /home/mc/xdg-user-dirs/media/job/log/ -type f -not -name '*.log' -not -name '*.error' | sort | tail -n 2 | head -n 1)
}
function m() {
    mount | grep ^/ | sort
}
function vip() {
    vi -p $(find $@ -type f | sort)
}
function vio() {
    vi -o $@
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
function inv() {
    screen -c /etc/screenrc bash /home/mc/xdg-user-dirs/media/bin/debug.sh inv
}
function invk() {
    bash /home/mc/xdg-user-dirs/media/bin/debug.sh invk
}
function vinfom() {
    if [ -z "$1" ];then
        mplayer dvd:////dev/sr0 -vo null -ao null -frames 0 -v 2>&1 | egrep '([as]id|VIDEO: |AUDIO: |Selected audio codec: | Track ID )'
    else
        mplayer -vo null -ao null -frames 0 -v "$1" 2>&1 | egrep '(VIDEO: |AUDIO: |Selected audio codec: | Track ID )'
    fi
}
function vinfof() {
    for f in $@;do
        ls -sh $f
        ffmpeg -i $f 2>&1 | egrep 'Stream #|Duration:' | sed -r -e 's/^[[:space:]]+//'
        echo
    done
}
function epgdumpy() {
    python2 /home/mc/xdg-user-dirs/media/bin/epgdump_py/epgdump.py $@
}
function epgdumpypy() {
    pypy /home/mc/xdg-user-dirs/media/bin/epgdump_py/epgdump.py $@
}
function seltitle() {
xmlstarlet sel --encode utf-8 -t \
    -m '//programme' -n \
    -v title -o '	' \
    -v '@start' -o '	' \
    -v '@stop' -o '	' \
    -v 'category[1]' -o '	' \
    -v 'category[2]' -o '	' \
    -v 'category[3]' -o '	' \
    -v 'category[4]' -o '	' \
    -v 'category[5]' -o '	' \
    --var 'channel=@channel' \
    -m '..//channel' -i '@id=$channel' -v '@id' -o '	' -v 'display-name[1]' -o '	' \
    $@ | xmlstarlet unesc |
python2 -c '
import datetime
import sys
for line in sys.stdin:
    arr = line.rstrip().split("\t")
    if arr and 10 <= len(arr):
        start = datetime.datetime.strptime(arr[1].split()[0], "%Y%m%d%H%M%S")
        end   = datetime.datetime.strptime(arr[2].split()[0], "%Y%m%d%H%M%S")
        start_date = start.strftime("%m/%d")
        start_time = start.strftime("%H:%M")
        end_time = end.strftime("%H:%M")

        print "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s" % (start_date, start_time, end_time, arr[8], arr[9], arr[0], arr[3], arr[4], arr[5], arr[6], arr[7])

' | column -t -s '	'
}
function seltime() {
    xmlstarlet sel --encode utf-8 -t -m '//programme' -v '@channel' -o ' ' -v '@start' -o ' ' -v '@stop' -n $@ |
    python2 -c '
import datetime
import sys
for line in sys.stdin:
    str = line.split()
    if len(str) == 5:
        print "%s %s %s" % (str[0], datetime.datetime.strptime(str[1], "%Y%m%d%H%M%S"), datetime.datetime.strptime(str[3], "%Y%m%d%H%M%S"))'
}
function selcategory() {
(
    category='アニメ'
    while getopts c: OPT
    do
        case $OPT in
            c)
                category=$OPTARG
                ;;
        esac
    done
    shift $((OPTIND - 1))

    xmlstarlet sel --encode utf-8 -t \
        -m '//programme' \
        -m "category[contains(., '$category')]" \
        -n \
        -v ../title -o '	' \
        -v '../@start' -o '	' \
        -v '../@stop' -o '	' \
        --var 'channel=../@channel' \
        -m '../..//channel' -i '@id=$channel' \
        -v '@id' -o '	' \
        -v 'display-name[1]' \
        $@ | xmlstarlet unesc |
python2 -c '
import datetime
import sys
for line in sys.stdin:
    arr = line.rstrip().split("\t")
    if arr and 5 <= len(arr):
        start = datetime.datetime.strptime(arr[1].split()[0], "%Y%m%d%H%M%S")
        end   = datetime.datetime.strptime(arr[2].split()[0], "%Y%m%d%H%M%S")
        start_date = start.strftime("%m/%d")
        start_time = start.strftime("%H:%M")
        end_time = end.strftime("%H:%M")

        print "%s\t%s\t%s\t%s\t%s\t%s" % (start_date, start_time, end_time, arr[3], arr[4], arr[0])

' | column -t -s '	'

)
}
function smbaterm() {
    smbclient -A ~/.smbauth '//ATERM-CE6499/hts54806-1'
}
function smbput() {
    smbclient -A ~/.smbauth '//ATERM-CE6499/hts54806-1' -c "put $@"
}
function pdiff() {
    work_dir=/home/mc/xdg-user-dirs/media/dpkg
    today=$(date +%Y%m%d)
    new=${work_dir}/${today}

    dpkg -l > $new
    old=${work_dir}/$(ls -1t $work_dir | sed -ne '2p')

    old_tmp=$(mktemp)
    new_tmp=$(mktemp)
    grep ^ii $old | awk '{ print $2 }' > $old_tmp
    grep ^ii $new | awk '{ print $2 }' > $new_tmp
cat << EOF

old : $(basename $old)
new : $(basename $new)

EOF
    diff -s --unified=0 $old_tmp $new_tmp
}
function wstat() {
    log_dir=/home/mc/xdg-user-dirs/media/job/state/pidstat

    if [ -n "$1" -a -f ${log_dir}/${1} ];then
        log_file=${log_dir}/${1}
    else
        log_file=${log_dir}/$(date +%Y%m%d)
    fi

    if [ -n "$2" ];then
        egrep -v '(kB_ccwr/s|^Linux|^$)' $log_file | grep "$2" |
        awk '
{
    if (1024 < $5 * 60) {
        printf("%s\t%dMB\t", $1, $5 * 60 / 1024)
        for (i = 8; i <= NF; i++)
            printf("%s ", $i)
        printf("\n")
    }
}' | column -t -s '	'
    else
        egrep -v '(kB_ccwr/s|^Linux|^$)' $log_file |
        awk '{ printf("%s    %s\n", $8, $5) }' | sort |
        awk '
        {
            proc = $1
            size = $2
            arr[proc] += int(size) * 60
        }
        END {
            for (proc in arr) {
                if ( 0 < arr[proc] ) {
                    printf("%dMB    %s\n", arr[proc] / 1024, proc)
                }
            }
        }' | sort -n | column -t
    fi
}

if [ -z "$DISPLAY" -a "$(tty)" = "/dev/tty1" ];then
    bash /home/mc/xdg-user-dirs/media/bin/play-station-controller.sh login_session &
fi
