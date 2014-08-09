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
delete from grouping        where created_at < strftime('%s','now') - 60 * 60 * 24 * 30 * 6;
delete from keywords        where created_at < strftime('%s','now') - 60 * 60 * 24 * 30 * 6;
delete from category        where created_at < strftime('%s','now') - 60 * 60 * 24 * 30 * 6;
vacuum;
"""

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
where series_id = -1
and channel = ?
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

sql_5 = u"""
insert or ignore into grouping
(
    channel,
    category_id,
    weekday,
    period
)
    select
    channel,
    category_id,
    weekday,
    period
    from programme
    where series_id = -1
    and group_id = -1
    group by channel, category_id, weekday, period;
"""

sql_6 = u"""
update programme
set updated_at = strftime('%s','now'),
group_id = ?
where series_id = -1
and group_id = -1
and channel = ?
and category_id = ?
and weekday = ?
and period = ?
"""

####################################################################################################

class Aggregater:
    def __init__(self):
        self.con = sqlite3.connect(DB_FILE)
        self.con.row_factory = sqlite3.Row
    def __del__(self):
        self.con.close()
    def normalize(self, title):
        bracket_s = False
        bracket_e = False
        bracket_name_s = ""
        bracket_name_e = ""
        s = ""

        for c in title:

            if bracket_s == True and bracket_e == True:
                s += " "
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

    def is_series(self, prev, cur):
        ret = True
        if prev == None:
            ret = False
        elif prev["title_normalize"][:3] != cur["title_normalize"][:3]:
            ret = False
        elif abs(prev["start"] - cur["start"]) < 60 * 60 * 24 * 6:
            ret = False
        return ret

    def parse_keyword(self, prev, cur):
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

        word_list_all = re.split("\s+", k)
        if differ and len(word_list_all) > 1:
            word_list = word_list_all[:len(word_list_all) -1]
        else:
            word_list = word_list_all

        key_list = []
        for i in word_list:
            if len(i) < 2:
                continue
            if re.match("^[0-9]+$", i):
                continue
            key_list.append(i)
        return key_list
    def delete_old_record(self):
        self.con.executescript(sql_1)
    def create_group_for_keyword(self):
        self.con.executescript(sql_2)
        csr = self.con.cursor()
        csr.execute(u"select * from tmp_group;")
        tmp_group = csr.fetchall()
        csr.close()
        return tmp_group
    def create_keyword(self, tmp_group):
        key_list_all = []
        for r1 in tmp_group:

            self.con.execute(u"delete from tmp_title")
            csr = self.con.cursor()
            csr.execute(sql_3, (r1["channel"], r1["category_id"], r1["weekday"], r1["period"]))
            title_list = csr.fetchall()
            csr.close()

        #     print "%s %s %s %s" % (r1["channel"], r1["category_id"], r1["weekday"], r1["period"])

            for r2 in title_list:
                title = self.normalize(r2["title"])
                self.con.execute(sql_4, (r2["channel"], r2["start"], title))

            csr = self.con.cursor()
            csr.execute(u"select * from tmp_title order by title_normalize, start")
            title_norm_list = csr.fetchall()
            csr.close()

            prev = None
            for cur in title_norm_list:
                if not self.is_series(prev, cur):
                    prev = cur
                    continue
        #         print cur["title_normalize"].encode("utf-8")
                key_list_all.append(self.parse_keyword(prev, cur))
                prev = cur

        key_list_uniq = []
        for k in key_list_all:
            if len(k) != 0 and not k in key_list_uniq:
                key_list_uniq.append(k)

        return key_list_uniq

    def insert_keyword(self, key_list_uniq):
        for k in key_list_uniq:
        #     s = ""
        #     for kk in k:
        #         s += kk + ","
        #     print s.encode("utf-8")

            csr = self.con.cursor()
            csr.execute(u"select max(series_id) as series_id from series")
            row = csr.fetchone()
            if row and row["series_id"]:
                series_id = row["series_id"] + 1
            else:
                series_id = 1
            csr.close()

            keyword_length = 0
            for keyword in k:
                keyword_length += len(keyword)
                self.con.execute(u"insert into keywords (series_id, keyword) values (?, ?)", (series_id, keyword))

            self.con.execute(u"insert into series (series_id, keyword_length) values (?, ?)", (series_id, keyword_length))

    def create_series(self):
        csr = self.con.cursor()
        csr.execute(u"select series_id from series order by keyword_length desc")
        series_list = csr.fetchall()
        csr.close()

        key_list = []
        for series_id in series_list:
            csr = self.con.cursor()
            csr.execute(u"select keyword from keywords where series_id = ?", series_id)
            l = []
            for k in csr.fetchall():
                l.append(k[0])
            key_list.append((series_id[0], l))
            csr.close()

        for k in key_list:
        #     s = ""
        #     s += str(k[0]) + ","
        #     for kk in k[1]:
        #         s += kk + ","
        #     print s

            sql =  u" update programme "
            sql += u" set updated_at = strftime('%s','now'), "
            sql += u" group_id = -1, "
            sql += u" series_id = " + str(k[0])
            sql += u" where series_id = -1 "
            for kk in k[1]:
                sql += u" and title like '%" + kk + "%'"
        #     print sql
            ret = self.con.execute(sql)

        csr = self.con.cursor()
        csr.execute(u"select count(*) as count, series_id from programme where series_id != -1 group by series_id")
        count_list = csr.fetchall()
        csr.close()

        for c in count_list:
            self.con.execute(u"update series set updated_at = strftime('%s','now'), series_count = ? where series_id = ?",
                         (c["count"], c["series_id"])
                       )

    def create_group_for_rating(self):
        self.con.executescript(sql_5)
        csr = self.con.cursor()
        csr.execute(u"select * from grouping")
        group_list = csr.fetchall()
        csr.close()
        for g in group_list:
            self.con.execute(sql_6, (g["group_id"], g["channel"], g["category_id"], g["weekday"], g["period"]))

    def execute(self):
        self.delete_old_record()
        tmp_group = self.create_group_for_keyword()
        key_list_uniq = self.create_keyword(tmp_group)
        self.insert_keyword(key_list_uniq)
        self.create_series()
        self.create_group_for_rating()

        self.con.commit()
        self.con.close()

####################################################################################################


if __name__ == '__main__':
    a = Aggregater()
    a.execute()
