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

class Provider:
    def __init__(self):
        self.con = sqlite3.connect(DB_FILE, isolation_level=None)
        self.con.row_factory = sqlite3.Row
    def __del__(self):
        self.con.close()
    def is_favorite_element(self, element):
        (channel, category_1, category_2, title_left, title_norm) = self.get_element_text(element)
        return self.is_favorite_db(channel, category_1, category_2, title_left, title_norm)
    def is_favorite_xml(self, xml_file):
        tree = ElementTree()
        tree.parse(xml_file)
        elem = tree.find("programme")
        (channel, category_1, category_2, title_left, title_norm) = self.get_element_text(elem)
        return self.is_favorite_db(channel, category_1, category_2, title_left, title_norm)
    def get_element_text(self, element):
        title = element.find('title').text
        title_norm = re.sub(u" ", "", unicodedata.normalize('NFKC', title))
        title_left = title_norm[:2]
        channel = element.get('channel')
        category_1 = ''
        category_2 = ''
        i = 0
        for c in element.findall('category'):
            if i == 0:
                category_1 = c.text
            elif i == 1:
                category_2 = c.text
            i += 1
        return (channel, category_1, category_2, title_left, title_norm)
    def is_favorite_db(self, channel, category_1, category_2, title_left, title_norm):
        ret = False
        csr = self.con.cursor()
        for row in csr.execute(sql_1, (channel, category_1, category_2, title_left + u"%")):
            if row["title"] == title_norm[:len(row["title"])]:
                ret = True
                break
        csr.close()
        return ret


if __name__ == '__main__':
    xml_file = sys.argv[1]
    p = Provider()
    if True == p.is_favorite_xml(xml_file):
        ret = 0
    else:
        ret = 1
    sys.exit(ret)
