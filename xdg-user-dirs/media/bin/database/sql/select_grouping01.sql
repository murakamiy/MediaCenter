.mode column
.width 4, 4, 4, 100

select
A.group_id,
A.weekday,
A.period,
B.title
from grouping as A
inner join programme as B on (A.group_id = B.group_id)
where B.title like '%'
order by A.group_id
;

.mode list
