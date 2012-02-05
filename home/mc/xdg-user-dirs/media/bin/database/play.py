#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import signal
from time import sleep
from xml.etree.cElementTree import ElementTree
from xml.etree.cElementTree import Element
import sqlite3

####################################################################################################
sql = u"""
update play set
    play_time_total =
    (
        select
            case
                when length < play_time_total + ? then
                    length
                else
                    play_time_total + ?
            end
        from play
        where service_id = ?
        and event_id = ?
    ),
    play_time_queue =
    (
        select
            case
                when length < play_time_total + ? then
                    play_time_queue + (length - play_time_total)
                else
                    play_time_queue + ?
            end
        from play
        where service_id = ?
        and event_id = ?
    ),
    updated_at = strftime('%s','now')
where service_id = ? 
and event_id = ?
"""
####################################################################################################
def update(signum, frame):
    con = sqlite3.connect("/home/mc/xdg-user-dirs/media/bin/database/tv.db", isolation_level=None)
    con.execute(sql,
            (
                play_time,
                play_time,
                service_id,
                event_id,
                play_time,
                play_time,
                service_id,
                event_id,
                service_id,
                event_id,
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
play_time = 0

signal.signal(signal.SIGHUP, update)
signal.signal(signal.SIGINT, update)
signal.signal(signal.SIGQUIT, update)
signal.signal(signal.SIGTERM, update)

while True:
    sleep(10)
    play_time += 10
