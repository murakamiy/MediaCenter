.mode column
.width 16, 3, 3, 60

.print "datetime        agg  time   title"

select
strftime('%Y/%m/%d %H:%M:%S', B.start, 'unixepoch', 'localtime'),
A.aggregate,
A.play_time / 60,
B.title
from play as A
inner join programme as B on
(
    A.channel = B.channel and
    A.start = B.start
)
order by B.start desc
limit 30
;

.mode list
