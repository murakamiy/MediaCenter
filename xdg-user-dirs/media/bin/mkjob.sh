#!/bin/bash
source $(dirname $0)/00.conf

temp=$(sensors | grep 'Physical id 0:' | awk -F : '{ print $2 }' | awk '{ print $1 }')
log "start: $temp"

touch ${MC_DIR_RECORDING}/mkjob.xml
trash-empty

today=$(date +%e)
fsck_span=$(($today % 14))
if [ $fsck_span -eq 0 ];then
    log "starting fsck"
    $MC_BIN_USB_POWER_ON
    sudo /sbin/fsck.ext4 -fy /dev/md0p1
    log "fsck usb_disk_array $?"
    sudo /sbin/fsck.ext4 -fy /dev/sde1
    log "fsck usb_disk $?"
fi

$MC_BIN_USB_MOUNT
bash $MC_BIN_MIGRATE array &
pid_mig_array=$!
bash $MC_BIN_MIGRATE encode &
pid_mig_encode=$!
bash $MC_BIN_SMB &
pid_smb=$!

wait $pid_mig_encode
wait $pid_smb
wait $pid_mig_array

log 'starting aggregate'
python ${MC_DIR_DB_RATING}/aggregate.py >> ${MC_DIR_DB_RATING}/log 2>&1

log 'starting create ts file'
for c in $(awk '{ print $1 }' $MC_FILE_CHANNEL_DIGITAL);do
    $MC_BIN_REC $c 60 ${MC_DIR_EPG}/${c}.ts
done
$MC_BIN_REC BS15_0 60 ${MC_DIR_EPG}/bs_cs_0.ts
$MC_BIN_REC CS2    60 ${MC_DIR_EPG}/bs_cs_2.ts
$MC_BIN_REC CS4    60 ${MC_DIR_EPG}/bs_cs_4.ts

log 'starting epgdump_py'
for ts in ${MC_DIR_EPG}/[0-9]*.ts;do
    channel=$(basename $ts .ts)
    python $MC_BIN_EPGDUMP -e -c $channel -i $ts -o ${MC_DIR_EPG}/${channel}.xml
done
python $MC_BIN_EPGDUMP -e -d -b -i ${MC_DIR_EPG}/bs_cs_0.ts -o ${MC_DIR_EPG}/bs_cs_0.xml
python $MC_BIN_EPGDUMP -e -d -s -i ${MC_DIR_EPG}/bs_cs_2.ts -o ${MC_DIR_EPG}/bs_cs_2.xml
python $MC_BIN_EPGDUMP -e -d -s -i ${MC_DIR_EPG}/bs_cs_4.ts -o ${MC_DIR_EPG}/bs_cs_4.xml

log 'starting find program'
python $MC_BIN_RESERVER '[0-9]*.xml' 'bs_cs_[0-9]*.xml'

log 'starting xml format'
for f in $(find $MC_DIR_RESERVED $MC_DIR_EPG -type f -name '*.xml');do
    temp_file=$(mktemp)
    xmlstarlet format --encode utf-8 $f > $temp_file
    /bin/mv $temp_file $f
done

/bin/rm -f ${MC_DIR_RECORDING}/mkjob.xml

temp=$(sensors | grep 'Physical id 0:' | awk -F : '{ print $2 }' | awk '{ print $1 }')
log "end: $temp"

bash $MC_BIN_SAFE_SHUTDOWN
