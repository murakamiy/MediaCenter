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

log 'starting clean'
bash $MC_BIN_CLEAN
log 'starting safe shutdown'
bash $MC_BIN_SAFE_SHUTDOWN
