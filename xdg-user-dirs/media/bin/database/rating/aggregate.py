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
vacuum;
"""
####################################################################################################
con = sqlite3.connect(DB_FILE)
con.row_factory = sqlite3.Row

con.executescript(sql_1)
con.commit()

con.close()
