#!/bin/bash
source $(dirname $0)/00.conf

function has_free_space() {
    used=$(df -Ph --sync | grep '/home' | awk '{ print $5 }' | tr -d '%' | egrep -o '^[0-9]+$')
    log "used: $used"
    if [ -z "$used" ];then
        return 0
    fi
    if [ $used -lt 60 ];then
        return 0
    fi
    return 1
}

count=0
while true;do
    has_free_space
    if [ $? -eq 0 ];then
        exit
    fi
    if [ $count -gt 10 ];then
        break
    fi
    ((count++))

    find ~/.local/share/Trash -type f -delete
    find $MC_DIR_RESUME -type f -delete

    for f in $(find $MC_DIR_JOB_FINISHED -type f);do
        base=$(basename ${f} .xml)
        if [ ! -f ${MC_DIR_TS}/${base}.ts ];then
            title=$(xmlsel -t -m '//title' -v '.' $f)
            log "delete_xml: $f $title"
            /bin/rm -f $f
        fi
    done

    for f in $(find $MC_DIR_ENCODE -type f);do
        base=$(basename $f | awk -F . '{ print $1 }')
        if [ -f "${MC_DIR_THUMB}/${base}" ];then
            inode=$(stat --format='%i' ${MC_DIR_THUMB}/${base})
            title=$(find $MC_DIR_TITLE_ENCODE -inum $inode)
            if [ ! -f "$title" ];then
                log "delete: $base encode"
                /bin/rm -f $f
                /bin/rm -f ${MC_DIR_ENCODE_FINISHED}/${base}.xml
            fi
        else
            ln -sf $f /home/mc/NO_TITLE_FILE_${base}
            ln -sf ${MC_DIR_ENCODE_FINISHED}/${base}.xml /home/mc/NO_TITLE_XML_${base}
        fi
    done

    for f in $(find $MC_DIR_TS -type f | sort);do
        base=$(basename $f | awk -F . '{ print $1 }')
        if [ -f "${MC_DIR_THUMB}/${base}" ];then
            inode=$(stat --format='%i' ${MC_DIR_THUMB}/${base})
            title=$(find $MC_DIR_TITLE_TS -inum $inode)
            if [ ! -f "$title" ];then
                title_jp=ts
                if [ -f "${MC_DIR_JOB_FINISHED}/${base}.xml" ];then
                    title_jp=$(xmlsel -t -m '//title' -v '.' ${MC_DIR_JOB_FINISHED}/${base}.xml)
                fi
                log "delete: $base $title_jp"
                /bin/rm -f $f
                /bin/rm -f ${MC_DIR_JOB_FINISHED}/${base}.xml
            fi
        else
            ln -sf $f /home/mc/NO_TITLE_FILE_TS_${base}
            ln -sf ${MC_DIR_JOB_FINISHED}/${base}.xml /home/mc/NO_TITLE_XML_TS_${base}
        fi

        has_free_space
        if [ $? -eq 0 ];then
            exit
        fi
    done

    for f in $(find $MC_DIR_THUMB -type f -links 1);do
        /bin/rm -f $f
    done

done
