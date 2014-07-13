#!/usr/bin/python
# -*- coding: utf-8 -*-

from constant import *
import sys
from xml.etree.cElementTree import ElementTree
from xml.etree.cElementTree import Element
import sqlite3

####################################################################################################
sql = u"""
insert into 
    programme (
        transport_stream_id,
        service_id,
        event_id,
        channel,
        title,
        desc,
        category_1,
        category_2,
        start,
        stop,
        priority,
        foundby,
        length
    )
    values (
        ?, ?, ?, ?, ?,
        ?, ?, ?, ?, ?,
        ?, ?, ?
    )
"""
####################################################################################################

xml_file = sys.argv[1]
tree = ElementTree()
tree.parse(xml_file)

el = tree.find("programme")
transport_stream_id = -1
v = el.find("transport-stream-id")
if v != None:
    transport_stream_id = int(v.text)
service_id = int(el.find("service-id").text)
event_id = int(el.find("event-id").text)
channel = el.get("channel")
title = el.find("title").text
desc = el.find("desc").text
category_1 = ""
category_2 = ""
i = 0
for c in el.findall('category'):
    if i == 0:
        category_1 = c.text
    elif i == 1:
        category_2 = c.text
    i += 1
priority = float(tree.find("priority").text)
foundby = tree.find("foundby").text
start = int(tree.find("epoch[@type='start']").text)
stop = int(tree.find("epoch[@type='stop']").text)
length = stop - start

con = sqlite3.connect(DB_FILE, isolation_level=None)

try:
    con.execute(sql,
            (
                transport_stream_id,
                service_id,
                event_id,
                channel,
                title,
                desc,
                category_1,
                category_2,
                start,
                stop,
                priority,
                foundby,
                length
            ))
except Exception, e:
    print e.__class__.__name__, ":", e
    print title
    print start, stop
    print transport_stream_id, service_id, event_id

con.close()
