#!/bin/bash
source $(dirname $0)/00.conf
source $(dirname $0)/smb_func.sh

smb_delete_dot_file
smb_bufferd_copy_mp4

find $MC_DIR_MP4 -ctime +5 -delete
