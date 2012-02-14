#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import sqlite3

####################################################################################################
sql_1 = u"""
insert into rating_category (category_1, category_2, length)
select
A.category_1, A.category_2, A.length
from
    (
        select
        category_1,
        category_2,
        sum(length) as length
        from programme
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
B.category_id
from programme as A
inner join rating_category as B on
(A.category_1 = B.category_1 and A.category_2 = B.category_2)
where A.category_id = -1
"""

sql_3 = u"""
update programme set
category_id = ?,
updated_at = strftime('%s','now')
where
transport_stream_id = ? and
service_id = ? and
event_id = ?
"""

sql_5 = u"""
insert into rating_series (category_id, title, length)
select A.category_id, A.title, sum(A.length) + sum(B.length)
from
(
    select 
    title,
    category_id,
    length
    from programme
    where series_id = -1
    and category_id != -1
    and (strftime('%s','now') - start) < 60 * 60 * 24 * 2
) as A
inner join
(
    select 
    title,
    category_id,
    length
    from programme
    where series_id = -1
    and category_id != -1
    and (strftime('%s','now') - start) between 60 * 60 * 24 * 5 and 60 * 60 * 24 * 21
) as B on (A.category_id = B.category_id and A.title = B.title)
group by A.category_id, A.title
"""

sql_6 = u"""
select A.series_id, B.transport_stream_id, B.service_id, B.event_id
from rating_series as A
inner join programme as B on (A.category_id = B.category_id and A.title = B.title)
where B.series_id = -1
and B.category_id != -1
"""

sql_7 = u"""
update programme set
series_id = ?,
identical = 1,
updated_at = strftime('%s','now')
where transport_stream_id = ?
and service_id = ?
and event_id = ?
"""
####################################################################################################

con = sqlite3.connect("/home/mc/xdg-user-dirs/media/bin/database/tv.db")
con.row_factory = sqlite3.Row

con.execute(sql_1)
con.commit()
csr = con.cursor()
param_programme = []
for row in csr.execute(sql_2):
    param_programme.append((
        row["category_id"],
        row["transport_stream_id"],
        row["service_id"],
        row["event_id"]))
csr.close()
for param in param_programme:
    con.execute(sql_3, param)
con.commit()

con.execute(sql_5)
con.commit()
csr = con.cursor()
param_programme = []
for row in csr.execute(sql_6):
    param_programme.append((
        row["series_id"],
        row["transport_stream_id"],
        row["service_id"],
        row["event_id"]))
csr.close()
for param in param_programme:
    con.execute(sql_7, param)
con.commit()
