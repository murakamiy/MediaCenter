#!/bin/bash
source $(dirname $0)/00.conf
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

log 'starting create ts file'
if [ "$MC_DEBUG_ENABLED" != "true" ];then
    i=0
    last=$(tail -n 1 $MC_FILE_CHANNEL)
    for c in $(cat $MC_FILE_CHANNEL);do
        rec $c 60 ${MC_DIR_EPG}/${c}.ts
    done
fi

(
cd $MC_DIR_EPG
mc2xml -c jp -g 5720825 -U -R ${MC_DIR_BIN}/mc2xml.ren <<EOF
3
EOF
)

log 'starting epgdump'
for ts in ${MC_DIR_EPG}/*.ts;do
    channel=$(basename $ts .ts)
    epgdump $channel $ts ${MC_DIR_EPG}/${channel}.xml || /bin/rm -f ${MC_DIR_EPG}/${channel}.xml
done

log 'starting find program'
python $MC_BIN_RESERVER

log 'starting xml format'
for f in $(find $MC_DIR_RESERVED $MC_DIR_EPG -type f -name '*.xml');do
    temp_file=$(mktemp)
    xmlstarlet format --encode utf-8 $f > $temp_file
    /bin/mv $temp_file $f
done

log 'starting epgdump_py'
(
cd ${MC_DIR_EPG}/work
for ts in ${MC_DIR_EPG}/*.ts;do
    channel=$(basename $ts .ts)
    python /home/mc/xdg-user-dirs/media/bin/epgdump_py/epgdump.py -c $channel -i $ts -o ${MC_DIR_EPG}/work/${channel}.xml
    temp_file=$(mktemp)
    xmlstarlet format --encode utf-8 ${MC_DIR_EPG}/work/${channel}.xml > $temp_file
    /bin/mv $temp_file ${MC_DIR_EPG}/work/${channel}.xml
    seltime ${MC_DIR_EPG}/${channel}.xml > ${channel}e
    seltime ${MC_DIR_EPG}/work/${channel}.xml > ${channel}p
    diff -u ${channel}e ${channel}p > ${channel}.diff
    if [ $? -eq 0 ];then
        log "$channel epgdump epgdump_py are identical"
    else
        cat ${channel}.diff >> $MC_FILE_LOG
    fi
    rm -f ${channel}e ${channel}p ${channel}.diff 
done
)


log 'starting clean'
bash $MC_BIN_CLEAN
log 'starting safe shutdown'
bash $MC_BIN_SAFE_SHUTDOWN
