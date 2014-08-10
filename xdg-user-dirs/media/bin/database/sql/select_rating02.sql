.mode column
.width 16, 4, 60

select
strftime('%Y/%m/%d %H:%M:%S', A.updated_at, 'unixepoch', 'localtime'),
A.rating,
B.title
from grouping as A
inner join programme as B on (A.group_id = B.group_id)
order by A.rating desc
limit 30
;

.mode list
