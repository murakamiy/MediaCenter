#!/bin/bash

# cat: /dev/dvb/adapter3/dvr0: Value too large for defined data type

src_dir=linux-source-3.5.0

/bin/cp $(ls /boot/config* | grep generic | sort | tail -n 1) $src_dir/.config

(
export CONCURRENCY_LEVEL=3
cd $src_dir
patch --dry-run -Np1 -i ../dvr_buffer_size.patch > /dev/null 2>&1
if [ $? -ne 0 ];then
    echo "ERROR: could not apply patch"
    exit
fi  
patch -Np1 -i ../dvr_buffer_size.patch 
make-kpkg --jobs 3 --rootcmd fakeroot --initrd --revision=$(date +%Y%m%d) kernel_image
)
