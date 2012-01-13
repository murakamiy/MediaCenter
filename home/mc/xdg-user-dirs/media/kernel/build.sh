#!/bin/bash
src_dir=linux-source-3.0.0

/bin/cp $(ls /boot/config* | sort | tail -n 1) $src_dir/.config

(
export CONCURRENCY_LEVEL=3
cd $src_dir
patch --dry-run -Np1 -i ../dvr_buffer_size.patch  
if [ $? -ne 0 ];then
    echo "ERROR: could not apply patch"
    exit
fi  
patch -Np1 -i ../dvr_buffer_size.patch 
sudo make-kpkg --jobs 3 --initrd --revision=$(date +%Y%m%d) kernel_image
)
