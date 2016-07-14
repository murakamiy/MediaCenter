#!/bin/bash
source $(dirname $0)/00.conf
source $(dirname $0)/smb_func.sh

work_dir=$(mktemp -d)

smb_get_play_log $work_dir
python2 ${MC_DIR_DB_RATING}/playsmb.py $work_dir >> ${MC_DIR_DB_RATING}/log 2>&1
