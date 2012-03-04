#!/bin/bash

sqlite3 tv.db '.dump play' > sql/dump.sql
rm -f tv.db
sqlite3 tv.db '.read sql/create_table.sql'
for f in $(grep -rl transport-stream-id /home/mc/xdg-user-dirs/media/job/state/04_job_finished/);do
    echo $(basename $f)
    python create.py $f
done
