.mode column
.width 60, 60
select
title,
smb_filename
from programme
order by start desc
limit 30
;

.mode list
