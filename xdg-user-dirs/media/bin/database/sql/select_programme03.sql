.mode line
select
A.title,
B.category_list
from programme as A
inner join category as B on (A.category_id = B.category_id)
order by A.start desc
limit 30
;

.mode list
