#!/bin/bash
source $(dirname $0)/00.conf

log "start: $(hard_ware_info)"

touch ${MC_DIR_RECORDING}/mkjob.xml
trash-empty

sudo $MC_BIN_MOUNT_TMP mount
$MC_BIN_USB_MOUNT
bash $MC_BIN_MIGRATE &
pid_mig_array=$!
bash $MC_BIN_SMB &
pid_smb=$!

log 'starting aggregate'
python ${MC_DIR_DB_RATING}/aggregate.py >> ${MC_DIR_DB_RATING}/log 2>&1

log 'starting epgdump_py digital'
for c in $(awk '{ print $1 }' $MC_FILE_CHANNEL_DIGITAL);do
    $MC_BIN_REC $c 60 ${MC_DIR_TMP}/${c}.ts
    python $MC_BIN_EPGDUMP -e -c $c -i ${MC_DIR_TMP}/${c}.ts -o ${MC_DIR_EPG}/${c}.xml
    /bin/rm ${MC_DIR_TMP}/${c}.ts
done

log 'starting epgdump_py bs cs'
$MC_BIN_REC BS15_0 60 ${MC_DIR_TMP}/bs_cs_0.ts
python $MC_BIN_EPGDUMP -e -d -b -i ${MC_DIR_TMP}/bs_cs_0.ts -o ${MC_DIR_EPG}/bs_cs_0.xml
/bin/rm ${MC_DIR_TMP}/bs_cs_0.ts
$MC_BIN_REC CS2    60 ${MC_DIR_TMP}/bs_cs_2.ts
python $MC_BIN_EPGDUMP -e -d -s -i ${MC_DIR_TMP}/bs_cs_2.ts -o ${MC_DIR_EPG}/bs_cs_2.xml
/bin/rm ${MC_DIR_TMP}/bs_cs_2.ts
$MC_BIN_REC CS4    60 ${MC_DIR_TMP}/bs_cs_4.ts
python $MC_BIN_EPGDUMP -e -d -s -i ${MC_DIR_TMP}/bs_cs_4.ts -o ${MC_DIR_EPG}/bs_cs_4.xml
/bin/rm ${MC_DIR_TMP}/bs_cs_4.ts

log 'starting find program'
python $MC_BIN_RESERVER '[0-9]*.xml' 'bs_cs_[0-9]*.xml'

log 'starting xml format'
for f in $(find $MC_DIR_RESERVED $MC_DIR_EPG -type f -name '*.xml');do
    temp_file=$(mktemp)
    xmlstarlet format --encode utf-8 $f > $temp_file
    /bin/mv $temp_file $f
done

wait $pid_smb
wait $pid_mig_array
sudo $MC_BIN_MOUNT_TMP unmount

running=$(find $MC_DIR_PLAY $MC_DIR_ENCODING -type f -name '*.xml' -printf '%f ')
if [ -z "$running" ];then
    $MC_BIN_USB_POWER_OFF
fi

/bin/rm -f ${MC_DIR_RECORDING}/mkjob.xml

log "end: $(hard_ware_info)"

bash $MC_BIN_SAFE_SHUTDOWN
