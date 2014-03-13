#!/bin/bash
source $(dirname $0)/00.conf
source $(dirname $0)/smb_func.sh

smb_print_disk_usage 'smb migrate start'

smb_delete_dot_file
smb_delete_old_file $(($MC_SMB_DISK_SIZE_GB * 1 / 3))
smb_bufferd_copy_mp4

smb_print_disk_usage 'smb migrate end  '

find $MC_DIR_MP4 -ctime +5 -delete
