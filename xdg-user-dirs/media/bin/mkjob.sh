#!/bin/bash
source $(dirname $0)/00.conf

log "start: $(hard_ware_info)"

touch ${MC_DIR_RECORDING}/mkjob.xml
trash-empty
sudo $MC_BIN_MOUNT_TMP mount

rec_time=60
prefix_digital=digital
prefix_bs_cs=bs_cs

log 'starting epgdump_py digital'
array=($(awk '{ print $1 }' $MC_FILE_CHANNEL_DIGITAL))
prefix=$prefix_digital
for ((i = 0; i < ${#array[@]}; i++));do
    $MC_BIN_REC ${array[$i]} $rec_time ${MC_DIR_TMP}/${prefix}_${array[$i]}.ts
    (
        python $MC_BIN_EPGDUMP -e -c ${array[$i]} -i ${MC_DIR_TMP}/${prefix}_${array[$i]}.ts -o ${MC_DIR_EPG}/${prefix}_${array[$i]}.xml
        /bin/rm ${MC_DIR_TMP}/${prefix}_${array[$i]}.ts
    ) &
    pid_epg_digital_dump=$!
    if [ $i -eq $((${#array[@]} -1)) ];then
        wait $pid_epg_digital_dump
    fi
done &
pid_epg_digital=$!

log 'starting epgdump_py bs cs'
array=(BS15_0 CS2 CS4)
prefix=$prefix_bs_cs
for ((i = 0; i < ${#array[@]}; i++));do
    $MC_BIN_REC ${array[$i]} $rec_time ${MC_DIR_TMP}/${prefix}_${array[$i]}.ts
    if [ "${array[$i]:0:2}" = "BS" ];then
        epg_param=" -b "
    elif [ "${array[$i]:0:2}" = "CS" ];then
        epg_param=" -s "
    fi
    (
        python $MC_BIN_EPGDUMP -e -d $epg_param -i ${MC_DIR_TMP}/${prefix}_${array[$i]}.ts -o ${MC_DIR_EPG}/${prefix}_${array[$i]}.xml
        /bin/rm ${MC_DIR_TMP}/${prefix}_${array[$i]}.ts
    ) &
    pid_epg_bs_cs_dump=$!
    if [ $i -eq $((${#array[@]} -1)) ];then
        wait $pid_epg_bs_cs_dump
    fi
done &
pid_epg_bs_cs=$!


$MC_BIN_USB_MOUNT
bash $MC_BIN_MIGRATE &
pid_mig_array=$!
bash $MC_BIN_SMB &
pid_smb=$!

log 'starting rrd'
bash $MC_BIN_RRD

log 'starting aggregate'
python ${MC_DIR_DB_RATING}/aggregate.py >> ${MC_DIR_DB_RATING}/log 2>&1

wait $pid_epg_bs_cs
wait $pid_epg_digital
log 'starting find program'
python $MC_BIN_RESERVER "${prefix_digital}_*.xml" "${prefix_bs_cs}_*.xml"

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
