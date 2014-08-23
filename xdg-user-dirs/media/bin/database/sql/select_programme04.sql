.mode column
.width 16, 4, 6, 8, 15, 60

.print "datetime          day  period   channel   finder           title"

select
strftime('%Y/%m/%d %H:%M:%S', start, 'unixepoch', 'localtime'),
case weekday
    when 1 then 'Mon'
    when 2 then 'Tue'
    when 3 then 'Wed'
    when 4 then 'Thu'
    when 5 then 'Fri'
    when 6 then 'Sat'
    when 7 then 'Sun'
end,
case period
    when 1 then '00-03'
    when 2 then '03-06'
    when 3 then '06-09'
    when 4 then '09-12'
    when 5 then '12-15'
    when 6 then '15-18'
    when 7 then '18-21'
    when 8 then '21-24'
end,
channel,
foundby,
title
from programme
where series_id = -1
and title like '%'
order by title, start
;

.mode list
