#!/bin/bash
source $(dirname $0)/00.conf

trash-empty
find $MC_DIR_MP4 -ctime +3 -delete
for f in $(smbclient -A ~/.smbauth -D contents -c "ls" $MC_SMB_SERVER |
    egrep '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' |
    awk -F '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' '
    {
        "date +%Y%m%d%H%M%S -d \""$2"\"" | getline time
        printf("%d\t%s\n", time, $1)
    }' | sort -k 1 -n -r | sed -n -e '301,$p' | awk '{ print $2 }');do

    smbclient -A ~/.smbauth -D contents -c "del $f" $MC_SMB_SERVER

done
