#!/bin/bash
source $(dirname $0)/00.conf
source $(dirname $0)/smb_func.sh

smb_delete_dot_file
smb_copy_mp4 all
smb_move_old_files
smb_put_log
smb_delete_empty_dir
