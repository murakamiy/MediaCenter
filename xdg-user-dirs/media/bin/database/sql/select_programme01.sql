.mode column
.width 16, 2, 8, 15, 60
select
strftime('%Y/%m/%d %H:%M:%S', start, 'unixepoch', 'localtime'),
period,
channel,
foundby,
title
from programme
order by start desc
limit 30
;

.mode list
