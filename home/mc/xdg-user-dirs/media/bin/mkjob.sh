#!/bin/bash
source $(dirname $0)/00.conf

log 'starting create ts file'
for c in $(cat $MC_FILE_CHANNEL);do
    rec $c 60 ${MC_DIR_EPG}/${c}.ts
done
rec 101 60 ${MC_DIR_EPG}/bs.ts

log 'starting epgdump_py'
for ts in ${MC_DIR_EPG}/[0-9]*.ts;do
    channel=$(basename $ts .ts)
    python $MC_BIN_EPGDUMP -c $channel -i $ts -o ${MC_DIR_EPG}/${channel}.xml
done
python $MC_BIN_EPGDUMP -b -i ${MC_DIR_EPG}/bs.ts -o ${MC_DIR_EPG}/bs.xml

log 'starting find program'
python $MC_BIN_RESERVER

log 'starting xml format'
for f in $(find $MC_DIR_RESERVED $MC_DIR_EPG -type f -name '*.xml');do
    temp_file=$(mktemp)
    xmlstarlet format --encode utf-8 $f > $temp_file
    /bin/mv $temp_file $f
done


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
log 'starting epgdump'
(
cd ${MC_DIR_EPG}/work
for ts in ${MC_DIR_EPG}/*.ts;do
    channel=$(basename $ts .ts)
    epgdump $channel $ts ${MC_DIR_EPG}/work/${channel}.xml
    temp_file=$(mktemp)
    xmlstarlet format --encode utf-8 ${MC_DIR_EPG}/work/${channel}.xml > $temp_file
    /bin/mv $temp_file ${MC_DIR_EPG}/work/${channel}.xml
    seltime ${MC_DIR_EPG}/${channel}.xml > ${channel}p
    seltime ${MC_DIR_EPG}/work/${channel}.xml > ${channel}e
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
