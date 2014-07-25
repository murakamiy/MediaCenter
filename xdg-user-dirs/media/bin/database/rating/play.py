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
insert into play (channel, start, play_time)
values (?, ?, ?)
"""
####################################################################################################
def update(signum, frame):
    con = sqlite3.connect(DB_FILE, isolation_level=None)
    con.execute(sql,
            (
                channel,
                start,
                play_time
            ))
    con.close()
    sys.exit()
####################################################################################################

xml_file = sys.argv[1]
tree = ElementTree()
tree.parse(xml_file)

el = tree.find("programme")
channel = el.get("channel")
start = int(tree.find("epoch[@type='start']").text)

play_time = 0

signal.signal(signal.SIGHUP, update)
signal.signal(signal.SIGINT, update)
signal.signal(signal.SIGQUIT, update)
signal.signal(signal.SIGTERM, update)

while True:
    sleep(10)
    play_time += 10
