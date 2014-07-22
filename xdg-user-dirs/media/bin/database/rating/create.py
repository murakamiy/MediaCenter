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
        title,
        channel,
        category,
        start,
        stop,
        foundby
    )
    values (
        ?, ?, ?, ?, ?,
        ?, ?, ?, ?
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
title = el.find("title").text
channel = el.get("channel")
category = ""
for c in el.findall('category'):
    category += c.text + ","
foundby = tree.find("foundby").text
start = int(tree.find("epoch[@type='start']").text)
stop = int(tree.find("epoch[@type='stop']").text)

con = sqlite3.connect(DB_FILE, isolation_level=None)

try:
    con.execute(sql,
            (
                transport_stream_id,
                service_id,
                event_id,
                title,
                channel,
                category,
                start,
                stop,
                foundby,
            ))
except Exception, e:
    print "####################################################################################################"
    print e.__class__.__name__, ":", e
    print title.decode("utf-8")
    print start, stop
    print transport_stream_id, service_id, event_id
    print "####################################################################################################"

con.close()
