.mode column
.width 4, 4, 6, 4, 10, 60

.print "id    day  period   count channel     category"

select
A.group_id,
case A.weekday
    when 1 then 'Mon'
    when 2 then 'Tue'
    when 3 then 'Wed'
    when 4 then 'Thu'
    when 5 then 'Fri'
    when 6 then 'Sat'
    when 7 then 'Sun'
end,
case A.period
    when 1 then '00-03'
    when 2 then '03-06'
    when 3 then '06-09'
    when 4 then '09-12'
    when 5 then '12-15'
    when 6 then '15-18'
    when 7 then '18-21'
    when 8 then '21-24'
end,
B.count,
A.channel,
C.category_list
from grouping as A
inner join (
    select *
    from (
        select D.group_id, count(*) as count
        from grouping as D
        inner join programme as E on (D.group_id = E.group_id)
        group by D.group_id
    )
    order by count desc
    limit 30
) as B on (A.group_id = B.group_id)
inner join category as C on (A.category_id = C.category_id)
;

.mode list
