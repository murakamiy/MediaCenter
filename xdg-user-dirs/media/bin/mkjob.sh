#!/bin/bash
source $(dirname $0)/00.conf

temp=$(sensors | grep 'Physical id 0:' | awk -F : '{ print $2 }' | awk '{ print $1 }')
lavg=$(uptime | awk -F 'average: ' '{ print $2 }' | tr -d ' ')
log "start: $temp lavg=$lavg"

touch ${MC_DIR_RECORDING}/mkjob.xml
trash-empty

today=$(date +%e)
fsck_span=1
do_fsck=$(($today % $fsck_span))
if [ $do_fsck -eq 0 ];then
    log "starting fsck"
    $MC_BIN_USB_POWER_ON

    sudo /sbin/fsck.ext4 -fy /dev/md0p1
    fsck_stat=$?
    log "fsck usb_disk_array $fsck_stat"
    if [ $fsck_stat -ne 0 ];then
        sudo /sbin/fsck.ext4 -fy /dev/md0p1
        fsck_stat=$?
        log "fsck usb_disk_array $fsck_stat"
    fi

    sudo /sbin/fsck.ext4 -fy /dev/sde1
    fsck_stat=$?
    log "fsck usb_disk $fsck_stat"
    if [ $fsck_stat -ne 0 ];then
        sudo /sbin/fsck.ext4 -fy /dev/sde1
        fsck_stat=$?
        log "fsck usb_disk $fsck_stat"
    fi
fi

sudo $MC_BIN_MOUNT_TMP mount
$MC_BIN_USB_MOUNT
bash $MC_BIN_MIGRATE array &
pid_mig_array=$!
bash $MC_BIN_SMB &
pid_smb=$!

log 'starting aggregate'
python ${MC_DIR_DB_RATING}/aggregate.py >> ${MC_DIR_DB_RATING}/log 2>&1

log 'starting epgdump_py digital'
for c in $(awk '{ print $1 }' $MC_FILE_CHANNEL_DIGITAL);do
    $MC_BIN_REC $c 60 ${MC_DIR_TMP}/${c}.ts
    python $MC_BIN_EPGDUMP -e -c $channel -i ${MC_DIR_TMP}/${c}.ts -o ${MC_DIR_EPG}/${c}.xml
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

temp=$(sensors | grep 'Physical id 0:' | awk -F : '{ print $2 }' | awk '{ print $1 }')
lavg=$(uptime | awk -F 'average: ' '{ print $2 }' | tr -d ' ')
log "end: $temp lavg=$lavg"

bash $MC_BIN_SAFE_SHUTDOWN
