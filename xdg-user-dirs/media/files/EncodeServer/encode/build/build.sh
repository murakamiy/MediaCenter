#!/bin/bash

yaourt -G ffmpeg

patch --dry-run -d ffmpeg/ -Np0 -i ../nvidia.patch
if [ $? -eq 0 ];then
    patch -d ffmpeg/ -Np0 -i ../nvidia.patch
else
    exit
fi

(
    cd ffmpeg
    makepkg --skippgpcheck
)
