.mode column
.width 4, 4, 100

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
