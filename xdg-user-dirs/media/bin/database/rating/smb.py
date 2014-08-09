#!/usr/bin/python
# -*- coding: utf-8 -*-

from constant import *
import sys
import traceback
from xml.etree.cElementTree import ElementTree
from xml.etree.cElementTree import Element
import sqlite3

####################################################################################################
sql = u"""
update
programme
set updated_at = strftime('%s','now'),
smb_filename = ?
where channel = ?
and start = ?
"""
####################################################################################################

xml_file = sys.argv[1]
smb_filename = sys.argv[2].decode("utf-8")

tree = ElementTree()
tree.parse(xml_file)

el = tree.find("programme")
channel = el.get("channel")
start = int(tree.find("epoch[@type='start']").text)

con = sqlite3.connect(DB_FILE, isolation_level=None)

try:
    con.execute(sql,
            (
                smb_filename,
                channel,
                start
            ))
except Exception, e:
    print "####################################################################################################"
    traceback.print_tb(sys.exc_info()[2])
    print e.__class__.__name__, ":", e
    print channel, start
    print "####################################################################################################"

con.close()
