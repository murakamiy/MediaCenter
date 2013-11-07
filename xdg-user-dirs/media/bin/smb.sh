#!/bin/bash
source $(dirname $0)/00.conf

avail=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk -F . '{ print $2 }')
log "smb migrate start $avail"

total_size=0
total_count=0
for f in $(smbclient -A ~/.smbauth -D contents -c "ls" $MC_SMB_SERVER |
    egrep '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' |
    awk -F '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' '
    {
        "date +%Y%m%d%H%M%S -d \""$2"\"" | getline time
        printf("%d\t%s\n", time, $1)
    }' | sort -k 1 -n -r | sed -n -e '301,$p' | awk '{ print $2 }');do

    size=$(smbclient -A ~/.smbauth -D contents -c "ls \"$f\"" $MC_SMB_SERVER |
    head -n 1 | awk -F ' A ' '{ print $2 }' | awk '{ print $1}')
    total_size=$(($total_size + $size))
    total_count=$(($total_count + 1))

    smbclient -A ~/.smbauth -D contents -c "del \"$f\"" $MC_SMB_SERVER

done

log "smb delete $total_count files $(($total_size / 1024 / 1024))MB"

cd $MC_DIR_TMP
for f in $(cd $MC_DIR_MP4; find . -name '*.mp4' -size +10M -printf '%f\n');do
    fuser "${MC_DIR_MP4}/$f"
    if [ $? -ne 0 ];then
        cp "${MC_DIR_MP4}/$f" $MC_DIR_TMP
        log "smb migrate put $(ls -sh $f)"
        smbclient -A ~/.smbauth -D contents -c "put \"$f\"" $MC_SMB_SERVER
        /bin/rm "${MC_DIR_MP4}/$f"
        /bin/rm "${MC_DIR_TMP}/$f"
    fi
done

avail=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk -F . '{ print $2 }')
log "smb migrate end $avail"

find $MC_DIR_MP4 -ctime +5 -delete
