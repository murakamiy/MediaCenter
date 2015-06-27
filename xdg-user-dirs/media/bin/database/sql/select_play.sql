.mode column
.width 16, 3, 3, 60

.print "datetime        agg  time   title"

select
strftime('%Y/%m/%d %H:%M:%S', A.created_at, 'unixepoch', 'localtime'),
A.aggregate,
A.play_time / 60,
B.title
from play as A
inner join programme as B on
(
    A.channel = B.channel and
    A.start = B.start
)
where B.title like '%'
order by A.created_at desc
limit 30
;

.mode list
