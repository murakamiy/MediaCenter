.mode column
.width 16, 4, 6, 6, 60

select
strftime('%Y/%m/%d %H:%M:%S', B.start, 'unixepoch', 'localtime'),
A.rating,
A.play_time,
A.length,
A.title
from rating_series as A
inner join programme as B on (A.series_id = B.series_id)
order by A.rating desc
limit 10
;

.mode list
