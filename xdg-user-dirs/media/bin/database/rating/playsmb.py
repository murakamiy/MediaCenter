#!/usr/bin/python
# -*- coding: utf-8 -*-

from constant import *
from glob import glob
import sys
from xml.etree.cElementTree import ElementTree
from xml.etree.cElementTree import Element
import sqlite3

####################################################################################################
sql_1 = u"""
select channel, start
from programme
where smb_filename = ?
"""

sql_2 = u"""
insert into play (channel, start, play_time)
values (?, ?, ?)
"""
####################################################################################################

xml_dir = sys.argv[1]

con = sqlite3.connect(DB_FILE, isolation_level=None)
con.row_factory = sqlite3.Row

for xml_file in glob(xml_dir + '/' + '*.xml'):
    tree = ElementTree()
    tree.parse(xml_file)
    smb_filename = tree.find("file").text
    play_time = int(tree.find("time").text)

    csr = con.cursor()
    csr.execute(sql_1, (smb_filename,))
    row = csr.fetchone()
    csr.close()

    if row:
        channel = row["channel"]
        start = row["start"]
        con.execute(sql_2, (channel, start, play_time)) 

con.close()
