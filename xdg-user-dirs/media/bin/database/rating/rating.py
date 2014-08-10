#!/usr/bin/python
# -*- coding: utf-8 -*-

from constant import *
import sys
import sqlite3
import re
import unicodedata
from xml.etree.cElementTree import ElementTree
from xml.etree.cElementTree import Element
from datetime import timedelta

####################################################################################################
sql_2 = u"""
select
count(*) as count
from programme
where title = ?
and
(
    (
        channel != ?
        and
        start > ? - 60 * 60 * 24 * 14
    )
    or
    (
        channel = ?
        and
        start > ? - 60 * 60 * 24 * 6
    )
)
"""

sql_3 = u"""
select
A.rating
from grouping as A
inner join category as B on (A.category_id = B.category_id)
where A.channel = ?
and A.weekday = ?
and A.period = ?
and B.category_list = ?
"""

####################################################################################################

class Provider:
    def __init__(self):
        self.con = sqlite3.connect(DB_FILE, isolation_level=None)
        self.con.row_factory = sqlite3.Row
    def __del__(self):
        self.con.close()
    def get_rating(self, pinfo):
        rating_v = self.get_rating_by_series(pinfo)
        if rating_v == 0:
            rating_v = self.get_rating_by_grouping(pinfo)
        return rating_v
    def get_rating_by_series(self, pinfo):

        title = pinfo.title.decode("utf-8")

        csr = self.con.cursor()
        csr.execute(u"select series_id, rating from series where rating != 0 order by keyword_length desc")
        series_list = csr.fetchall()
        csr.close()

        key_list = []
        for s in series_list:
            csr = self.con.cursor()
            csr.execute(u"select keyword from keywords where series_id = ?", (s["series_id"],))
            l = []
            for k in csr.fetchall():
                l.append(k["keyword"])
            key_list.append((s["rating"], l))
            csr.close()

        for k in key_list:
            match = None
            for word in k[1]:
                match = re.search(word, title)
                if not match:
                    break
            if match:
                return k[0]

        return 0
    def get_rating_by_grouping(self, pinfo):
        category = ""
        for c in pinfo.category_list:
            category += c + ","

        minute_29 = timedelta(0, 60 * 29, 0)
        period = (pinfo.start + minute_29).hour / 3 + 1
        weekday = pinfo.start.isoweekday()

        csr = self.con.cursor()
        csr.execute(sql_3, (pinfo.channel.decode("utf-8"), weekday, period, category.decode("utf-8")))
        row = csr.fetchone()
        rating_v = 0
        if row and row["rating"]:
            rating_v = row["rating"]
        csr.close()

        return rating_v
    def has_same_record(self, title, channel, start):
        csr = self.con.cursor()
        csr.execute(sql_2, (title, channel, start, channel, start))
        row = csr.fetchone()
        count = row["count"]
        csr.close()
        if count > 0:
            ret = True
        else:
            ret = False
        return ret
