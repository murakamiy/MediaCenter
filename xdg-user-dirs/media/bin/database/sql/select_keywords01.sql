.mode column
.width 4, 4, 100

select
B.keyword_length,
A.series_id,
A.keyword
from keywords as A
inner join series as B on (A.series_id = B.series_id)
order by B.keyword_length desc
;

.mode list
