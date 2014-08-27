.mode column
.width 16, 4, 4, 60

.print "datetime         len   id     keyword"

select
strftime('%Y/%m/%d %H:%M:%S', B.created_at, 'unixepoch', 'localtime'),
B.keyword_length,
A.series_id,
A.keyword
from keywords as A
inner join series as B on (A.series_id = B.series_id)
order by B.keyword_length desc
;

.mode list
