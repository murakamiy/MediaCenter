#!/usr/bin/python
# -*- coding: utf-8 -*-

from constant import *
import sys
from xml.etree.cElementTree import ElementTree
from xml.etree.cElementTree import Element
import sqlite3

####################################################################################################
sql = u"""
update
programme
set smb_filename = ?
where transport_stream_id = ?
and service_id = ?
and event_id = ?
"""
####################################################################################################

xml_file = sys.argv[1]
smb_filename = sys.argv[2]

tree = ElementTree()
tree.parse(xml_file)

el = tree.find("programme")
transport_stream_id = -1
v = el.find("transport-stream-id")
if v != None:
    transport_stream_id = int(v.text)
service_id = int(el.find("service-id").text)
event_id = int(el.find("event-id").text)

con = sqlite3.connect(DB_FILE, isolation_level=None)

try:
    con.execute(sql,
            (
                smb_filename,
                transport_stream_id,
                service_id,
                event_id,
            ))
except Exception, e:
    print "####################################################################################################"
    print e.__class__.__name__, ":", e
    print transport_stream_id, service_id, event_id
    print "####################################################################################################"

con.close()
