#!/bin/bash
source $(dirname $0)/00.conf

touch ${MC_DIR_RECORDING}/mkjob.xml

log 'starting aggregate'
python ${MC_DIR_DB_RATING}/aggregate.py >> ${MC_DIR_DB_RATING}/log 2>&1

log 'starting create ts file'
$MC_BIN_REC BS15_0 60 ${MC_DIR_EPG}/bs_cs_0.ts
for c in $(awk '{ print $1 }' $MC_FILE_CHANNEL_DIGITAL);do
    $MC_BIN_REC $c 60 ${MC_DIR_EPG}/${c}.ts
done
cs_channel_array=(2 4)
for c in ${cs_channel_array[@]};do
    $MC_BIN_REC CS${c} 60 ${MC_DIR_EPG}/bs_cs_${c}.ts
done

log 'starting epgdump_py'
for ts in ${MC_DIR_EPG}/[0-9]*.ts;do
    channel=$(basename $ts .ts)
    python $MC_BIN_EPGDUMP -e -c $channel -i $ts -o ${MC_DIR_EPG}/${channel}.xml
done
python $MC_BIN_EPGDUMP -e -d -b -i ${MC_DIR_EPG}/bs.ts -o ${MC_DIR_EPG}/bs.xml
for ts in ${MC_DIR_EPG}/cs_[0-9]*.ts;do
    channel=$(basename $ts .ts)
    python $MC_BIN_EPGDUMP -e -d -s -i $ts -o ${MC_DIR_EPG}/${channel}.xml
done

log 'starting find program'
python $MC_BIN_RESERVER '[0-9]*.xml' 'bs_cs_[0-9]*.xml'

log 'starting xml format'
for f in $(find $MC_DIR_RESERVED $MC_DIR_EPG -type f -name '*.xml');do
    temp_file=$(mktemp)
    xmlstarlet format --encode utf-8 $f > $temp_file
    /bin/mv $temp_file $f
done

log 'starting clean'
bash $MC_BIN_CLEAN

/bin/rm -f ${MC_DIR_RECORDING}/mkjob.xml
log 'starting safe shutdown'
bash $MC_BIN_SAFE_SHUTDOWN
