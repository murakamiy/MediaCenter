#!/usr/bin/python
# -*- coding: utf-8 -*-

from constant import *
import sys
import sqlite3
import re
import unicodedata
from xml.etree.cElementTree import ElementTree
from xml.etree.cElementTree import Element

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
####################################################################################################

class Provider:
    def __init__(self):
        self.con = sqlite3.connect(DB_FILE, isolation_level=None)
        self.con.row_factory = sqlite3.Row
    def __del__(self):
        self.con.close()
    def get_rating_element(self, element):
        return 0
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
