#!/bin/bash
source $(dirname $0)/../00.conf

bash ${MC_DIR_RRD}/graph.sh
bash ${MC_DIR_RRD}/put.sh
