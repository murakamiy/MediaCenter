.mode column
.width 16, 6, 4, 60

.print "datetime          rating  id    keyword"

select
strftime('%Y/%m/%d %H:%M:%S', A.updated_at, 'unixepoch', 'localtime'),
A.rating,
A.series_id,
B.keyword
from series as A
inner join keywords as B on (A.series_id = B.series_id)
order by A.rating desc
limit 30
;

.mode list
