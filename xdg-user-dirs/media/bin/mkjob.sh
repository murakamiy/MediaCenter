#!/bin/bash
source $(dirname $0)/00.conf

temp=$(sensors | grep 'Physical id 0:' | awk -F : '{ print $2 }' | awk '{ print $1 }')
log "start: $temp"

touch ${MC_DIR_RECORDING}/mkjob.xml

$MC_BIN_USB_POWER_ON
bash /home/mc/xdg-user-dirs/media/bin/migrate.sh array &
pid_mig_array=$!
bash /home/mc/xdg-user-dirs/media/bin/migrate.sh encode &
pid_mig_encode=$!

log 'starting clean'
bash $MC_BIN_CLEAN
(
    cd $MC_DIR_MP4
    for f in *.mp4;do
        fuser "$f"
        if [ $? -ne 0 -a -s "$f" ];then
            smbclient -A ~/.smbauth -D contents -c "put $f" $MC_SMB_SERVER
            /bin/rm $f
        fi
    done
) &
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
