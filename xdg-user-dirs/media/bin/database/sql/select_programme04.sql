.mode column
.width 16, 2, 2, 8, 15, 80

select
strftime('%Y/%m/%d %H:%M:%S', A.start, 'unixepoch', 'localtime'),
A.weekday,
A.period,
A.channel,
A.foundby,
A.title
from programme as A
inner join
(
    select *
    from
    (
        select
        count(*) as count,
        channel,
        category_id,
        weekday,
        period
        from programme
        where series_id = -1
        group by channel, category_id, weekday, period
    )
    where count > 1
) as B on
    (
        A.channel = B.channel
        and
        A.category_id = B.category_id
        and
        A.weekday = B.weekday
        and
        A.period = A.period
    )
where A.title like '%'
order by A.start desc
;

.mode list
