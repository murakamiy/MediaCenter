#!/bin/bash
source $(dirname $0)/config

mkdir -p $EN_DIR_XML
mkdir -p ${EN_DIR_LOG}/{gpu,cpu}

find $EN_DIR_XML $EN_DIR_LOG -type f -ctime +7 -delete
