.mode column
.width 16, 4, 6, 60

select
strftime('%Y/%m/%d %H:%M:%S', updated_at, 'unixepoch', 'localtime'),
rating,
play_time,
keyword
from series
order by rating desc
limit 30
;

.mode list
