insert into rating_category (category_1, category_2)
select
A.category_1, A.category_2
from
    (
        select
        category_1, category_2
        from play
        where category_id = -1
        group by category_1, category_2
    ) as A
left outer join rating_category as B on
    (
        A.category_1 = B.category_1 and
        A.category_2 = B.category_2
    )
where B.category_1 is null
;
