#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import sqlite3
import re
import unicodedata

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
select C.category_id, C.title, C.sum from
(
    select A.category_id, A.title, sum(A.length) + sum(B.length) as sum
    from
    (
        select 
        title,
        category_id,
        length
        from programme
        where series_id = -1
        and category_id != -1
        and (strftime('%s','now') - start) < 60 * 60 * 25
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
        and (strftime('%s','now') - start) between 60 * 60 * 24 * 7 and 60 * 60 * 24 * 8
    ) as B on (A.category_id = B.category_id and A.title = B.title)
    group by A.category_id, A.title
) as C
left outer join rating_series as D on (C.category_id = D.category_id and C.title = D.title)
where D.category_id is null
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

sql_8 = u"""
select 
transport_stream_id,
service_id,
event_id,
category_id,
title,
length
from programme
where series_id = -1
and category_id != -1
and (strftime('%s','now') - start) < 60 * 60 * 25
"""

sql_9 = u"""
select 
A.transport_stream_id,
A.service_id,
A.event_id,
A.category_id,
A.title,
A.length
from programme as A
left outer join rating_series as B on
(A.series_id = B.series_id)
where A.identical = 0
and A.category_id != -1
and (strftime('%s','now') - A.start) between 60 * 60 * 24 * 7 and 60 * 60 * 24 * 8
"""

sql_10 = u"""
select series_id from rating_series
where category_id = ?
and title = ?
"""

sql_11 = u"""
insert into rating_series (category_id, title, length)
values (?, ?, ?)
"""

sql_12 = u"""
update rating_series set
length = length + ?,
updated_at = strftime('%s','now')
where series_id = ?
"""

sql_13 = u"""
update programme set
series_id = ?,
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

csr = con.cursor()
csr.execute(sql_8)
sql_new = csr.fetchall()
csr.close()
csr = con.cursor()
csr.execute(sql_9)
sql_old = csr.fetchall()
csr.close()

pattern = re.compile(u" ")
list_new = []
list_old = []
for l in sql_new:
    m = {}
    m["title_left"] = unicodedata.normalize('NFKC', l["title"][:2])
    m["title_sub"] = re.sub(pattern, '', unicodedata.normalize('NFKC', l["title"]))
    m["title_identical"] = u""
    m["sql_row"] = l
    list_new.append(m)
for l in sql_old:
    m = {}
    m["title_left"] = unicodedata.normalize('NFKC', l["title"][:2])
    m["title_sub"] = re.sub(pattern, '', unicodedata.normalize('NFKC', l["title"]))
    m["sql_row"] = l
    list_old.append(m)

for new in list_new:
    for old in list_old:
        if new["sql_row"]["category_id"] == old["sql_row"]["category_id"]:
            if new["title_left"] == old["title_left"]:
                length = max(len(new["title_sub"]), len(old["title_sub"]))
                for i in range(3, length + 1):
                    if new["title_sub"][2:i] != old["title_sub"][2:i]:
                        if len(new["title_identical"]) < i - 2:
                            print 'new', new["title_sub"]
                            new["title_identical"] = new["title_sub"][0:i - 2]
                        break

print
csr = con.cursor()
for l in list_new:
    if 2 < len(l["title_identical"]) and len(l["title_sub"]) / 3 < len(l["title_identical"]):
        csr.execute(sql_10, (l["sql_row"]["category_id"], l["title_identical"]))
        r = csr.fetchone()
        if r == None:
            csr.execute(sql_11, (l["sql_row"]["category_id"], l["title_identical"], l["sql_row"]["length"]));
            series_id = csr.lastrowid
            print 'insert', l["sql_row"]["category_id"], l["title_identical"], l["sql_row"]["length"]
        else:
            series_id = r["series_id"]
            csr.execute(sql_12, (l["sql_row"]["length"], series_id));
            print 'update', l["sql_row"]["length"], series_id

        csr.execute(sql_13, (series_id, l["sql_row"]["transport_stream_id"], l["sql_row"]["service_id"], l["sql_row"]["event_id"]))
        print 'update2', series_id, l["sql_row"]["transport_stream_id"], l["sql_row"]["service_id"], l["sql_row"]["event_id"]

con.commit()
