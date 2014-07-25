.mode column
.width 16, 1, 6, 60

select
strftime('%Y/%m/%d %H:%M:%S', B.start, 'unixepoch', 'localtime'),
A.aggregate,
A.play_time,
B.title
from play as A
inner join programme as B on
(
    A.channel = B.channel and
    A.start = B.start and
)
order by B.start desc
limit 30
;

.mode list
