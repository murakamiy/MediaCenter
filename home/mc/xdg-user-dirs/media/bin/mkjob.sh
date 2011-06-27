#!/bin/bash
source $(dirname $0)/00.conf

log 'starting create ts file'
for c in $(cat $MC_FILE_CHANNEL);do
    rec $c 60 ${MC_DIR_EPG}/${c}.ts
done

log 'starting epgdump_py'
for ts in ${MC_DIR_EPG}/*.ts;do
    channel=$(basename $ts .ts)
    python /home/mc/xdg-user-dirs/media/bin/epgdump_py/epgdump.py -c $channel -i $ts -o ${MC_DIR_EPG}/${channel}.xml
#     temp_file=$(mktemp)
#     xmlstarlet format --encode utf-8 ${MC_DIR_EPG}/${channel}.xml > $temp_file
#     /bin/mv $temp_file ${MC_DIR_EPG}/${channel}.xml
done

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
