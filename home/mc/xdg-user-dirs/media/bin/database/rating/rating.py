#!/usr/bin/python
# -*- coding: utf-8 -*-

from constant import *
import sys
import sqlite3
import re
import unicodedata
from xml.etree.cElementTree import ElementTree
from xml.etree.cElementTree import Element

####################################################################################################
sql_1 = u"""
select
A.title
from rating_series as A
inner join rating_category as B on (A.category_id = B.category_id)
where A.channel = ?
and B.category_1 = ?
and B.category_2 = ?
and A.rating > 0.6
and A.title like ?
"""
####################################################################################################

xml_file = sys.argv[1]

tree = ElementTree()
tree.parse(xml_file)
el = tree.find("programme")
title = el.find('title').text
title_norm = re.sub(u" ", "", unicodedata.normalize('NFKC', title))
title_left = title_norm[:2]
channel = el.get('channel')
category_1 = ''
category_2 = ''
i = 0
for c in el.findall('category'):
    if i == 0:
        category_1 = c.text
    elif i == 1:
        category_2 = c.text
    i += 1

con = sqlite3.connect(DB_FILE, isolation_level=None)
con.row_factory = sqlite3.Row

csr = con.cursor()
ret = 1
for row in csr.execute(sql_1, (channel, category_1, category_2, title_left + u"%")):
    if row["title"] == title_norm[:len(row["title"])]:
        ret = 0
        break
csr.close()
con.close()

sys.exit(ret)
