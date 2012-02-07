.mode column
.width 50, 20, 30

select
A.title, B.category_1, B.category_2
from play as A
inner join rating_category as B on
(A.category_id = B.category_id)
;
