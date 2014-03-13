#!/bin/bash

smb_dir=contents

function smb_get_disk_usage() {
    disk_size=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk '{ print $1 }')
    disk_avail=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk '{ print $6 }')
    echo "$MC_SMB_DISK_SIZE_GB * $disk_avail / $disk_size" | bc
}

function smb_print_disk_usage() {
    message=$1
    disk_avail_gb=$(smb_get_disk_usage)

    log "$message avail:${disk_avail_gb}GB"
}

function smb_bufferd_copy_mp4() {

    cd $MC_DIR_TMP
    for f in $(cd $MC_DIR_MP4; find . -name '*.mp4' -size +10M -printf '%f\n');do
        fuser "${MC_DIR_MP4}/$f"
        if [ $? -ne 0 ];then
            cp "${MC_DIR_MP4}/$f" $MC_DIR_TMP
            log "smb migrate put $(ls -sh $f)"
            smbclient -A ~/.smbauth -D $smb_dir -c "put \"$f\"" $MC_SMB_SERVER
            /bin/rm "${MC_DIR_MP4}/$f"
            /bin/rm "${MC_DIR_TMP}/$f"
        fi
    done

}

function smb_copy_mp4() {

    cd $MC_DIR_MP4
    mp4=$(find . -type f -size +10M -printf '%TY%Tm%Td %TT %f\n' | sort | head -n 1 | awk '{ print $3}')

    if [ -n "$mp4" ];then
        fuser "$mp4"
        if [ $? -ne 0 ];then

            smb_print_disk_usage "smb job put"

            smbclient -A ~/.smbauth -D $smb_dir -c "put \"$mp4\"" $MC_SMB_SERVER
            smbclient -A ~/.smbauth -D $smb_dir -c "ls \"$mp4\"" $MC_SMB_SERVER
            if [ $? -eq 0 ];then
                /bin/rm "$mp4"
            fi
        fi
    fi
}

function smb_delete_dot_file() {

    for f in $(smbclient -A ~/.smbauth -D $smb_dir -c "ls" $MC_SMB_SERVER |
        egrep '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' |
        awk '{ print $1 }' | grep '^\.');do

        smbclient -A ~/.smbauth -D $smb_dir -c "del \"$f\"" $MC_SMB_SERVER

    done
}

function smb_delete_old_file() {

    th=$1
    total_size=0
    total_count=0

    for f in $(smbclient -A ~/.smbauth -D $smb_dir -c "ls" $MC_SMB_SERVER |
        egrep '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' |
        awk -F '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' '
        {
            "date +%Y%m%d%H%M%S -d \""$2"\"" | getline time
            printf("%d\t%s\n", time, $1)
        }' | sort -k 1 -n | awk '{ print $2 }');do


        avail=$(smb_get_disk_usage)
        if [ $avail -gt $th ];then
            break
        fi

        size=$(smbclient -A ~/.smbauth -D $smb_dir -c "ls \"$f\"" $MC_SMB_SERVER |
        head -n 1 | awk -F ' A ' '{ print $2 }' | awk '{ print $1}')
        total_size=$(($total_size + $size))
        total_count=$(($total_count + 1))

        smbclient -A ~/.smbauth -D $smb_dir -c "del \"$f\"" $MC_SMB_SERVER

    done

    log "smb delete $total_count files $(($total_size / 1024 / 1024))MB"
}
