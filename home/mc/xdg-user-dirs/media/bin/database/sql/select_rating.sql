.mode column
.width 16, 4, 6, 6, 60

select
strftime('%Y/%m/%d %H:%M:%S', updated_at, 'unixepoch', 'localtime'),
rating,
play_time,
length,
title
from rating_series
order by rating desc
limit 30
;

.mode list
