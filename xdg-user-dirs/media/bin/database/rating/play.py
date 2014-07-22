#!/usr/bin/python
# -*- coding: utf-8 -*-

from constant import *
import sys
import signal
from time import sleep
from xml.etree.cElementTree import ElementTree
from xml.etree.cElementTree import Element
import sqlite3

####################################################################################################
sql = u"""
insert into play (transport_stream_id, service_id, event_id, play_time)
values (?, ?, ?, ?)
"""
####################################################################################################
def update(signum, frame):
    con = sqlite3.connect(DB_FILE, isolation_level=None)
    con.execute(sql,
            (
                transport_stream_id,
                service_id,
                event_id,
                play_time
            ))
    con.close()
    sys.exit()
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
play_time = 0

signal.signal(signal.SIGHUP, update)
signal.signal(signal.SIGINT, update)
signal.signal(signal.SIGQUIT, update)
signal.signal(signal.SIGTERM, update)

while True:
    sleep(10)
    play_time += 10
