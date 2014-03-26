#!/bin/bash

smb_dir=contents

function smb_get_disk_usage() {
    disk_size=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk '{ print $1 }')
    disk_avail=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk '{ print $6 }')
    echo "$MC_SMB_DISK_SIZE_GB * $disk_avail / $disk_size" | bc
}

function smb_bufferd_copy_mp4() {

    cd $MC_DIR_MP4
    for mp4 in $(find . -name '*.mp4' -size +10M -printf '%f\n');do

        fuser "$mp4"
        if [ $? -ne 0 ];then
            smb_delete_old_file $(($MC_SMB_DISK_SIZE_GB * 1 / 8))
            mp4_size=$(ls -sh "$mp4")
            log "smb migrate put $mp4_size"
            cp "$mp4" $MC_DIR_TMP
            /bin/rm "$mp4"
            (
                cd $MC_DIR_TMP
                smbclient -A ~/.smbauth -D $smb_dir -c "put \"$mp4\"" $MC_SMB_SERVER
                /bin/rm "$mp4"
            )
        fi

    done
}

function smb_copy_mp4() {

    cd $MC_DIR_MP4
    mp4=$(find . -type f -size +10M -printf '%TY%Tm%Td %TT %f\n' | sort | head -n 1 | awk '{ print $3}')

    if [ -n "$mp4" ];then
        fuser "$mp4"
        if [ $? -ne 0 ];then
            smb_delete_old_file $(($MC_SMB_DISK_SIZE_GB * 1 / 8))
            mp4_size=$(ls -sh "$mp4")
            log "smb job put $mp4_size"
            smbclient -A ~/.smbauth -D $smb_dir -c "put \"$mp4\"" $MC_SMB_SERVER
            /bin/rm "$mp4"
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

    if [ $total_count -gt 0 ];then
        avail=$(smb_get_disk_usage)
        log "smb delete $total_count files $(($total_size / 1024 / 1024))MB avail:${avail}GB"
    fi
}
