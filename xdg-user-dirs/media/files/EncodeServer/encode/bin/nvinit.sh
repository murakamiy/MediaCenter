#!/bin/bash
source $(dirname $0)/config

/usr/local/bin/NvTranscoder -i ${EN_DIR_ROOT}/input.h264 -o /dev/null
