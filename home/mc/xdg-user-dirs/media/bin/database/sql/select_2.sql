.mode column
.width 20 5 5 20 40

select
strftime('%Y/%m/%d %H:%M:%S', created_at, 'unixepoch', 'localtime'),
play_time,
length,
category_1,
category_2
from rating_category;
