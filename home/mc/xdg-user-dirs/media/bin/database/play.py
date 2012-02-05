#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import signal
from time import sleep
from time import localtime
from time import strftime
from xml.etree.cElementTree import ElementTree
from xml.etree.cElementTree import Element
import sqlite3

####################################################################################################
sql_insert = u"""
insert into 
    play (
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
        play_time,
        length
    )
    values (
        ?, ?, ?, ?, ?,
        ?, ?, ?, ?, ?,
        ?, ?, ?
    )
"""
####################################################################################################
def insert(signum, frame):
    global play_time
    global length
    if length < play_time:
        play_time = length
    con = sqlite3.connect("/home/mc/xdg-user-dirs/media/bin/database/tv.db", isolation_level=None)
    con.execute(sql_insert,
            (
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
                play_time,
                length
            ))
    con.close()
    sys.exit()
####################################################################################################

xml_file = sys.argv[1]
tree = ElementTree()
tree.parse(xml_file)

el = tree.find("programme")
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
priority = int(tree.find("priority").text)
foundby = tree.find("foundby").text
play_time = 0
start = int(tree.find("epoch[@type='start']").text)
stop = int(tree.find("epoch[@type='stop']").text)
length = stop - start

signal.signal(signal.SIGHUP, insert)
signal.signal(signal.SIGINT, insert)
signal.signal(signal.SIGQUIT, insert)
signal.signal(signal.SIGTERM, insert)

while True:
    sleep(10)
    play_time += 10
