.mode column
.width 16, 2, 2, 8, 15, 80
select
strftime('%Y/%m/%d %H:%M:%S', start, 'unixepoch', 'localtime'),
weekday,
period,
channel,
foundby,
title
from programme
where title like '%'
order by start desc
limit 30
;

.mode list
