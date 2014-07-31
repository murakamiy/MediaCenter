#!/bin/bash

smb_dir=contents

function smb_print_format() {
    local type=$1
    local dir=$2
    local line="$3"
    local separator='[[:space:]]A[[:space:]]+[0-9]+[[:space:]]'

    if [ "$type" = "directory" ];then
        separator='[[:space:]]DA[[:space:]]+[0-9]+[[:space:]]'
    fi

    awk -v dir=$dir -v type=$type -F $separator '
    {
        "date +%Y%m%d%H%M%S -d \""$2"\"" | getline time
        printf("%s\t%d\t%s/%s\n", type, time, dir, $1)
    }' <<< $line
}

function smb_print_base() {

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
                smb_print_format directory $dir "$line"
                smb_print_base ${dir}/${name}
            fi
        elif [ "$type" = "A" ];then
            smb_print_format file $dir "$line"
        fi
    done
}

function smb_print_file() {
    smb_print_base $1 | grep ^file | awk -F '\t' '{ printf("%s\t%s\n", $2, $3) }'
}

function smb_print_directory() {
    smb_print_base $1 | grep ^directory | awk -F '\t' '{ printf("%s\t%s\n", $2, $3) }'
}

function smb_get_disk_usage() {
    disk_size=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk '{ print $1 }')
    disk_avail=$(smbclient -A ~/.smbauth -c ls $MC_SMB_SERVER | tail -n 1 | awk '{ print $6 }')
    echo "$MC_SMB_DISK_SIZE_GB * $disk_avail / $disk_size" | bc
}

function smb_update_wtime() {
    empty_file_dir=/tmp
    empty_file_base=__smb_update__

    touch ${empty_file_dir}/${empty_file_base}
    (
        cd $empty_file_dir
        smbclient -A ~/.smbauth -D ${smb_dir}/Favorite -c "put $empty_file_base" $MC_SMB_SERVER
        smbclient -A ~/.smbauth -D ${smb_dir}/Favorite -c "del $empty_file_base" $MC_SMB_SERVER
        sleep 1
        smbclient -A ~/.smbauth -D ${smb_dir}/__NEW -c "put $empty_file_base" $MC_SMB_SERVER
        smbclient -A ~/.smbauth -D ${smb_dir}/__NEW -c "del $empty_file_base" $MC_SMB_SERVER
    )
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

            smbclient -A ~/.smbauth -D ${smb_dir} -c "mkdir __NEW" $MC_SMB_SERVER
            smbclient -A ~/.smbauth -D ${smb_dir}/__NEW -c "mkdir $foundby" $MC_SMB_SERVER
            smbclient -A ~/.smbauth -D ${smb_dir}/__NEW/${foundby} -c "put $mp4 \"$remote\"" $MC_SMB_SERVER
            /bin/rm "$mp4"

            python ${MC_DIR_DB_RATING}/smb.py $xml "$remote" >> ${MC_DIR_DB_RATING}/log 2>&1

        if [ "$1" = "one" ];then
            break
        fi

    done
    smb_update_wtime
}

function smb_move_old_files() {

    smb_print_file ${smb_dir}/__NEW | sort -k 1 -n |
    awk -F '\t' '
        function epoch_time(datetime) {
            year = substr(datetime, 1, 4)
            month = substr(datetime, 5, 2)
            day = substr(datetime, 7, 2)
            hour = substr(datetime, 9, 2)
            minute = substr(datetime, 11, 2)
            second = substr(datetime, 13, 2)
            return mktime(year" "month" "day" "hour" "minute" "second)
        }

        BEGIN {
            epoch_now = systime()
        }

        {
            past = $1
            file = $2
            epoch_past = epoch_time(past)
            format_past = strftime("%Y/%m/%d-%H:%M:%S", epoch_past)
            period = epoch_now - epoch_past
            format_period = sprintf("%02d:%02d", period / 3600, period % 3600 / 60)

            if (period > 1) { # 1day:86400 2days:172800
                printf("%s\t%s\t%s\t%s\n", format_period, past, format_past, file)
            }

        }
    ' | awk '{ print $4 }' |
    while read line;do
        file=$line
        base=$(basename $file)
        foundby=$(basename $(dirname $file))
        smbclient -A ~/.smbauth -D ${smb_dir} -c "mkdir $foundby" $MC_SMB_SERVER
        smbclient -A ~/.smbauth -c "rename \"$file\" \"${smb_dir}/${foundby}/${base}\"" $MC_SMB_SERVER
    done
}

function smb_delete_empty_dir() {
    for d in $(smb_print_directory $smb_dir | awk -F '\t' '{ print $2 }');do
        smbclient -A ~/.smbauth -c "rmdir $d" $MC_SMB_SERVER
    done
}

function smb_delete_dot_file() {
    for f in $(smb_print_file $smb_dir | awk -F '\t' '{ print $2 }' | grep '/\.');do
        dir_name=$(dirname $f)
        file_name=$(basename $f)
        smbclient -A ~/.smbauth -D $dir_name -c "del \"$file_name\"" $MC_SMB_SERVER
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

function smb_put_log() {

    count_mc=0
    count_mail=0
    for ff in $(smb_print_file log | sort -k 1 -nr | awk -F '\t' '{ print $2 }');do

        f=$(basename $ff)

        grep -q ^mc_ <<< $f
        if [ $? -eq 0 ];then
            ((count_mc++))
            if [ $count_mc -gt 2 ];then
                smbclient -A ~/.smbauth -D log -c "del $f" $MC_SMB_SERVER
            fi
        fi

        grep -q ^mail_ <<< $f
        if [ $? -eq 0 ];then
            ((count_mail++))
            if [ $count_mail -gt 2 ];then
                smbclient -A ~/.smbauth -D log -c "del $f" $MC_SMB_SERVER
            fi
        fi

    done

    yesterday=$(date --date=yesterday +%Y%m%d)

    (
        cd $MC_DIR_LOG
        smbclient -A ~/.smbauth -D log -c "put $yesterday mc_${yesterday}.txt" $MC_SMB_SERVER
    )

    mail=mail_${yesterday}.txt
    LC_ALL=C awk '
    BEGIN {
        begin = 0
        end = 0
        yesterday = strftime("^From .+ %a %b %d [0-9]{2}:[0-9]{2}:[0-9]{2} %Y$", systime() - 60 * 60 * 24)
        today     = strftime("^From .+ %a %b %d [0-9]{2}:[0-9]{2}:[0-9]{2} %Y$", systime())
    }

    {
        if (begin == 0 && match($0, yesterday)) {
            begin = 1
        }
        else if (begin == 1 && end == 0 && match($0, today)) {
            end = 1
        }
        if (begin == 1 && end == 0) {
            print $0
        }
    }
    ' /var/mail/mc > /tmp/$mail

    (
        cd /tmp
        smbclient -A ~/.smbauth -D log -c "put $mail" $MC_SMB_SERVER
    )
}

function smb_get_play_log() {

    work_dir=$1
    (
        cd $work_dir
        for ff in $(smb_print_file play_time | awk -F '\t' '{ print $2 }');do

            f=$(basename $ff)
            smbclient -A ~/.smbauth -D play_time -c "get $f" $MC_SMB_SERVER
            smbclient -A ~/.smbauth -D play_time -c "del $f" $MC_SMB_SERVER

        done
    )
}
