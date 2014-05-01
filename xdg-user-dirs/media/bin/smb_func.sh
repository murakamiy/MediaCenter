#!/bin/bash

smb_dir=contents

function smb_print_file() {

    local dir=$1
    local dir_opt="-D $dir"
    local line=
    local name=
    local type=

    smbclient -A ~/.smbauth $dir_opt -c "ls" $MC_SMB_SERVER 2> /dev/null |
    while read line;do
        name=$(awk '{ print $1 }' <<< $line)
        type=$(awk '{ print $2 }' <<< $line)
        if [ "$type" = "DA" ];then
            if [ "$name" != "." -a "$name" != ".." ];then
                smb_print_file ${dir}/${name}
            fi
        elif [ "$type" = "A" ];then
            awk -v dir=$dir -F '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' '
            {
                "date +%Y%m%d%H%M%S -d \""$2"\"" | getline time
                printf("%d\t%s/%s\n", time, dir, $1)
            }' <<< $line
        fi
    done
}

function smb_get_disk_usage() {
    disk_size=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk '{ print $1 }')
    disk_avail=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk '{ print $6 }')
    echo "$MC_SMB_DISK_SIZE_GB * $disk_avail / $disk_size" | bc
}

function smb_copy_mp4() {

    cd $MC_DIR_MP4
    for mp4 in $(find . -type f -size +10M -printf '%TY%Tm%Td %TT %f\n' | sort | awk '{ print $3}');do

        fuser "$mp4"
        if [ $? -eq 0 ];then
            continue
        fi

        smb_delete_old_file $(($MC_SMB_DISK_SIZE_GB * 1 / 5))

        xml=${MC_DIR_JOB_FINISHED}/$(basename $mp4 .mp4).xml
        title=$(print_title $xml)
        foundby=$(xmlsel -t -m //foundby -v . $xml | sed -e 's/Finder//')
        date=$(date +%m%d)
        remote=${title}_${date}.mp4
        mp4_size=$(ls -sh "$mp4")
        log "smb put $title"

        /bin/mv "$mp4" $MC_DIR_TMP
        (
            cd $MC_DIR_TMP
            smbclient -A ~/.smbauth -D $smb_dir -c "mkdir $foundby" $MC_SMB_SERVER
            smbclient -A ~/.smbauth -D ${smb_dir}/${foundby} -c "put $mp4 \"$remote\"" $MC_SMB_SERVER
            /bin/rm "$mp4"
        )

        if [ "$1" = "one" ];then
            break
        fi

    done
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

    for f in $(smb_print_file $smb_dir | sort -k 1 -n | awk -F '\t' '{ print $2 }');do

        avail=$(smb_get_disk_usage)
        if [ $avail -gt $th ];then
            break
        fi

        dir_name=$(dirname $f)
        file_name=$(basename $f)

        size=$(smbclient -A ~/.smbauth -D $dir_name -c "ls \"$file_name\"" $MC_SMB_SERVER |
        head -n 1 | awk -F ' A ' '{ print $2 }' | awk '{ print $1}')
        total_size=$(($total_size + $size))
        total_count=$(($total_count + 1))

        smbclient -A ~/.smbauth -D $dir_name -c "del \"$file_name\"" $MC_SMB_SERVER

    done

    if [ $total_count -gt 0 ];then
        avail=$(smb_get_disk_usage)
        log "smb delete $total_count files $(($total_size / 1024 / 1024))MB avail:${avail}GB"
    fi
}
