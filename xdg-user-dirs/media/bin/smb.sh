#!/bin/bash
source $(dirname $0)/00.conf

avail=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk -F . '{ print $2 }')
log "smb start $avail"

for f in $(smbclient -A ~/.smbauth -D contents -c "ls" $MC_SMB_SERVER |
    egrep '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' |
    awk -F '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' '
    {
        "date +%Y%m%d%H%M%S -d \""$2"\"" | getline time
        printf("%d\t%s\n", time, $1)
    }' | sort -k 1 -n -r | sed -n -e '71,$p' | awk '{ print $2 }');do

    smbclient -A ~/.smbauth -D contents -c "del $f" $MC_SMB_SERVER

done

avail=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk -F . '{ print $2 }')
log "smb delete end $avail"

cd $MC_DIR_TMP
for f in $(cd $MC_DIR_MP4; find . -name '*.mp4' -printf '%f\n');do
    fuser "${MC_DIR_MP4}/$f"
    if [ $? -ne 0 -a -s "${MC_DIR_MP4}/$f" ];then
        cp "${MC_DIR_MP4}/$f" $MC_DIR_TMP
        smbclient -A ~/.smbauth -D contents -c "put $f" $MC_SMB_SERVER
        /bin/rm "${MC_DIR_MP4}/$f"
        /bin/rm "${MC_DIR_TMP}/$f"
    fi
done

avail=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk -F . '{ print $2 }')
log "smb copy end $avail"

find $MC_DIR_MP4 -ctime +5 -delete
