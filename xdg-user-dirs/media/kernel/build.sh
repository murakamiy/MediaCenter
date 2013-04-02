#!/bin/bash

src_dir=linux-source-3.5.0

(
export CONCURRENCY_LEVEL=3
cd $src_dir
make-kpkg --jobs 3 --rootcmd fakeroot --initrd --revision=$(date +%Y%m%d) kernel_image
)
