#!/bin/bash
source $(dirname $0)/00.conf
source $(dirname $0)/smb_func.sh

smb_delete_dot_file
smb_copy_mp4 all
smb_move_old_files
smb_delete_empty_dir

find $MC_DIR_MP4 -ctime +5 -delete
