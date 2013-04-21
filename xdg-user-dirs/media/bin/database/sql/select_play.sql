.mode column
.width 16, 1, 6, 6, 60

select
strftime('%Y/%m/%d %H:%M:%S', B.start, 'unixepoch', 'localtime'),
A.aggregate,
A.play_time,
B.length,
B.title
from play as A
inner join programme as B on
(
    A.transport_stream_id = B.transport_stream_id and
    A.service_id = B.service_id and
    A.event_id = B.event_id
)
order by B.start desc
limit 30
;

.mode list
