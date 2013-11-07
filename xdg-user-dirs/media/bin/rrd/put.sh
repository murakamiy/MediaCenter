#!/bin/bash
source $(dirname $0)/00.conf

log "smb graph put start"
start_date=$(awk 'BEGIN { printf("%s\n", strftime("%Y%m%d\n", systime() - 60 * 60 * 24)) }')

work_dir=graph/daily 
for f in $(smbclient -A ~/.smbauth -D $work_dir -c "ls" $MC_SMB_SERVER |
    egrep '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' |
    awk -F '[[:space:]]A[[:space:]]+[0-9]+[[:space:]]' '
    {
        "date +%Y%m%d%H%M%S -d \""$2"\"" | getline time
        printf("%d\t%s\n", time, $1)
    }' | sort -k 1 -n -r | sed -n -e '43,$p' | awk '{ print $2 }');do

    smbclient -A ~/.smbauth -D $work_dir -c "del \"$f\"" $MC_SMB_SERVER

done

for f in ${MC_DIR_RRD}/png/*;do
    smbclient -A ~/.smbauth -D $work_dir -c "put \"$f\" \"${start_date}_$f\"" $MC_SMB_SERVER
done
