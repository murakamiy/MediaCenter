#!/usr/bin/python
# -*- coding: utf-8 -*-

from constant import *
import sys
import traceback
from xml.etree.cElementTree import ElementTree
from xml.etree.cElementTree import Element
import sqlite3
from datetime import datetime
from datetime import timedelta

####################################################################################################
sql = u"""
insert into
    programme (
        title,
        channel,
        category,
        period,
        start,
        stop,
        foundby
    )
    values (
        ?, ?, ?, ?, ?,
        ?, ?
    )
"""
####################################################################################################

xml_file = sys.argv[1]
tree = ElementTree()
tree.parse(xml_file)

el = tree.find("programme")
title = el.find("title").text
channel = el.get("channel")
category = ""
for c in el.findall('category'):
    category += c.text + ","
foundby = tree.find("foundby").text
start = int(tree.find("epoch[@type='start']").text)
stop = int(tree.find("epoch[@type='stop']").text)

minute_29 = timedelta(0, 60 * 29, 0)
period_start = datetime.fromtimestamp(start)
period = (period_start + minute_29).hour / 3 + 1


con = sqlite3.connect(DB_FILE, isolation_level=None)

try:
    con.execute(sql,
            (
                title,
                channel,
                category,
                period,
                start,
                stop,
                foundby,
            ))
except Exception, e:
    print "####################################################################################################"
    traceback.print_tb(sys.exc_info()[2])
    print e.__class__.__name__, ":", e
    print start, stop, channel
    print "####################################################################################################"

con.close()
