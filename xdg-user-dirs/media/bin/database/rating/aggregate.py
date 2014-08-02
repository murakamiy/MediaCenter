#!/usr/bin/python
# -*- coding: utf-8 -*-

from constant import *
import sys
import sqlite3
import re
import unicodedata

####################################################################################################
sql_1 = u"""
delete from play            where created_at < strftime('%s','now') - 60 * 60 * 24 * 30 * 6;
delete from programme       where created_at < strftime('%s','now') - 60 * 60 * 24 * 30 * 6;
delete from series          where created_at < strftime('%s','now') - 60 * 60 * 24 * 30 * 6;
delete from keywords        where created_at < strftime('%s','now') - 60 * 60 * 24 * 30 * 6;
delete from category        where created_at < strftime('%s','now') - 60 * 60 * 24 * 30 * 6;
vacuum;
"""

# sql_2
# update programme
# set series_id = -1
# where series_id in
# (
# select series_id
# from series
# where series_count = 1
# )

sql_2 = u"""
delete from tmp_group;
insert into tmp_group
(
    count,
    channel,
    category_id,
    weekday,
    period
)
    select *
    from
    (
        select
        count(*) as count,
        channel,
        category_id,
        weekday,
        period
        from programme
        where series_id = -1
        group by channel, category_id, weekday, period
    )
    where count > 1;
"""

sql_3 = u"""
select
channel,
start,
title
from programme
where channel = ?
and category_id = ?
and weekday = ?
and period = ?
"""

sql_4 = u"""
insert into tmp_title
(
    channel,
    start,
    title_normalize
)
values (?, ?, ?)
"""

####################################################################################################

def normalize(title):
    bracket_s = False
    bracket_e = False
    bracket_name_s = ""
    bracket_name_e = ""
    s = ""

    for c in title:
        if bracket_s == True and bracket_e == True:
            bracket_s = False
            bracket_e = False
        if bracket_s == False:
            if unicodedata.category(c) == "Ps":
                bracket_s = True
                bracket_name_s = re.sub("LEFT|RIGHT", "", unicodedata.name(c))
        elif bracket_e == False:
            if unicodedata.category(c) == "Pe":
                bracket_name_e = re.sub("LEFT|RIGHT", "", unicodedata.name(c))
                if bracket_name_s == bracket_name_e:
                    bracket_e = True
        if not bracket_s:
            s += c

    ss = ""
    for c in s:
        cat = unicodedata.category(c)[0]
        if cat == "P" or cat == "S" or cat == "Z":
            ss += " "
        else:
            ss += c

    return ss

def is_series(prev, cur):
    ret = True
    if prev == None:
        ret = False
    elif prev["title_normalize"][:3] != cur["title_normalize"][:3]:
        ret = False
    elif abs(prev["start"] - cur["start"]) < 60 * 60 * 24 * 6:
        ret = False
    return ret

def create_keyword(prev, cur):
    p = prev["title_normalize"]
    c = cur["title_normalize"]

    differ = False
    for i in range(0, min(len(p), len(c))):
        if p[i] != c[i]:
            differ = True
            break

    if differ:
        k = p[:i]
    else:
        k = p

#     print p.encode("utf-8"), c.encode("utf-8"), p[i].encode("utf-8"), c[i].encode("utf-8"), k.encode("utf-8")

    key_list = []
    for i in re.split("\s+", k):
        if len(i) < 3:
            continue
        if re.match("^[0-9]+$", i):
            continue
        key_list.append(i)
    return key_list

####################################################################################################
con = sqlite3.connect(DB_FILE)
con.row_factory = sqlite3.Row


con.executescript(sql_1)
con.commit()

con.executescript(sql_2)
con.commit()

csr = con.cursor()
csr.execute(u"select * from tmp_group;")
tmp_group = csr.fetchall()
csr.close()

key_list_all = []
for r1 in tmp_group:

    con.execute(u"delete from tmp_title")
    csr = con.cursor()
    csr.execute(sql_3, (r1["channel"], r1["category_id"], r1["weekday"], r1["period"]))
    title_list = csr.fetchall()
    csr.close()

#     print "%s %s %s %s" % (r1["channel"], r1["category_id"], r1["weekday"], r1["period"])

    for r2 in title_list:
        title = normalize(r2["title"])
        con.execute(sql_4, (r2["channel"], r2["start"], title))

    con.commit()

    csr = con.cursor()
    csr.execute(u"select * from tmp_title order by title_normalize, start")
    title_norm_list = csr.fetchall()
    csr.close()

    prev = None
    for cur in title_norm_list:
        if not is_series(prev, cur):
            prev = cur
            continue
#         print cur["title_normalize"].encode("utf-8")
        key_list_all.append(create_keyword(prev, cur))
        prev = cur

key_list_uniq = []
for k in key_list_all:
    if len(k) != 0 and not k in key_list_uniq:
        key_list_uniq.append(k)

for k in key_list_uniq:
#     s = ""
#     for kk in k:
#         s += kk + ","
#     print s.encode("utf-8")

    csr = con.cursor()
    csr.execute(u"select max(series_id) as series_id from series")
    row = csr.fetchone()
    if row:
        series_id = row["series_id"] + 1
    else:
        series_id = 1
    csr.close()

    con.execute(u"insert into series (series_id) values (?)", (series_id,))
    for keyword in k:
        con.execute(u"insert into keywords (series_id, keyword) values (?, ?)", (series_id, keyword))

    con.commit()


con.close()
