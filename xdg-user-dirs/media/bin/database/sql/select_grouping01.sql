.mode column
.width 4, 100

select
A.group_id,
B.title
from grouping as A
inner join programme as B on (A.group_id = B.group_id)
order by A.group_id
;

.mode list
