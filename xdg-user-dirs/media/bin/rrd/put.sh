#!/bin/bash
source $(dirname $0)/../00.conf

log "smb graph put start"

function delete_put() {

    prefix=$1
    cycle=$2
    stock=$3
    smb_dir=graph/${cycle}

    for f in $(smbclient -A ~/.smbauth -D $smb_dir -c "ls" $MC_SMB_SERVER |
        egrep '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' |
        awk '{ print $1 }' | grep '^\.');do

        smbclient -A ~/.smbauth -D $smb_dir -c "del \"$f\"" $MC_SMB_SERVER

    done

    for f in $(smbclient -A ~/.smbauth -D $smb_dir -c "ls" $MC_SMB_SERVER |
        egrep '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' |
        awk -F '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' '
        {
            "date +%Y%m%d%H%M%S -d \""$2"\"" | getline time
            printf("%d\t%s\n", time, $1)
        }' | sort -k 1 -n -r | sed -n -e "$stock,\$p" | awk '{ print $2 }');do

        smbclient -A ~/.smbauth -D $smb_dir -c "del \"$f\"" $MC_SMB_SERVER

    done

    for f in ${MC_DIR_RRD}/png/${cycle}/*;do
        b=$(basename $f)
        smbclient -A ~/.smbauth -D $smb_dir -c "put \"$f\" \"${prefix}_${b}\"" $MC_SMB_SERVER
    done
}


prefix=$(awk 'BEGIN { printf("%s\n", strftime("%Y%m%d\n", systime() - 60 * 60 * 24)) }')
delete_put $prefix daily 57
