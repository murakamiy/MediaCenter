.mode column
.width 20 4 4 80

select
strftime('%Y/%m/%d %H:%M:%S', created_at, 'unixepoch', 'localtime'),
play_time_total, play_time_queue, title
from play;
