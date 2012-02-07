#!/usr/bin/python
# -*- coding: utf-8 -*-

import sqlite3

####################################################################################################
sql_1 = u"""
insert into rating_category (category_1, category_2)
select
A.category_1, A.category_2
from
    (
        select
        category_1, category_2
        from play
        where category_id = -1
        group by category_1, category_2
    ) as A
left outer join rating_category as B on
    (
        A.category_1 = B.category_1 and
        A.category_2 = B.category_2
    )
where B.category_1 is null
"""

sql_2 = u"""
select
A.transport_stream_id, A.service_id, A.event_id,
A.length, B.category_id
from play as A
inner join rating_category as B on
(A.category_1 = B.category_1 and A.category_2 = B.category_2)
where A.category_id = -1
"""

sql_3 = u"""
update play set
category_id = ?
updated_at = strftime('%s','now')
where
transport_stream_id = ? and
service_id = ? and
event_id = ?
"""

sql_4 = u"""
update rating_category
set length = length + ?,
updated_at = strftime('%s','now')
where category_id = ?
"""
####################################################################################################

con = sqlite3.connect("/home/mc/xdg-user-dirs/media/bin/database/tv.db")
con.row_factory = sqlite3.Row

con.execute(sql_1);
con.commit()

csr = con.cursor()
param_play = []
param_rating_category = []
for row in csr.execute(sql_2):
    param_play.append((
        row["category_id"],
        row["transport_stream_id"],
        row["service_id"],
        row["event_id"]))
    param_rating_category.append((
        row["length"],
        row["category_id"]))
csr.close()

for param in param_play:
    con.execute(sql_3, param)
for param in param_rating_category:
    con.execute(sql_4, param)

con.commit()
