.mode column
.width 16, 8, 15, 60
select
strftime('%Y/%m/%d %H:%M:%S', start, 'unixepoch', 'localtime'),
channel,
foundby,
title
from programme
order by start desc
limit 30
;

.mode list
