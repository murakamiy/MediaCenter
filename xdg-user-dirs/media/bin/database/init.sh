#!/bin/bash

rm -f tv.db
sqlite3 tv.db '.read sql/create_table.sql'

for f in $(ls -t /home/mc/xdg-user-dirs/media/job/state/04_job_finished/ | sed -n -e '1,1000p');do
    ff=/home/mc/xdg-user-dirs/media/job/state/04_job_finished/$f
    echo $ff
    python rating/create.py $ff
done
