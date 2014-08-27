.mode column
.width 16, 6, 4, 60

.print "datetime          rating  id    title"

select
strftime('%Y/%m/%d %H:%M:%S', A.updated_at, 'unixepoch', 'localtime'),
A.rating,
A.group_id,
B.title
from grouping as A
inner join programme as B on (A.group_id = B.group_id)
order by A.rating desc
limit 30
;

.mode list
