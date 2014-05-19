#!/bin/bash

bash ../script/print_channel.sh > channel.txt
awk -f ../script/parse_log.awk log.txt > log_parsed.txt
awk -v log_file_name=log_parsed.txt -v channel_file_name=channel.txt \
    -f ../script/bind_channel.awk log_parsed.txt channel.txt > channel_bind.txt
