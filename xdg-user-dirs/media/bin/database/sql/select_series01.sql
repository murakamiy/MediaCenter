.mode column
.width 5, 4, 80

.print "count  id    title"

select
A.series_count,
A.series_id,
B.title
from series as A
inner join programme as B on (A.series_id = B.series_id)
where B.title like '%'
order by A.series_count desc, A.series_id
;

.mode list
