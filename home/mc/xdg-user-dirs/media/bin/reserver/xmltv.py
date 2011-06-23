# -*- coding: utf-8 -*-
import os
import os.path
from glob import glob
from xml.etree.cElementTree import ElementTree
from xml.etree.cElementTree import Element

DIR_EPG = os.environ["MC_DIR_EPG"]

class Credits:
    @classmethod
    def merge(cls):

        xmltv = ElementTree()
        xmltv.parse(DIR_EPG + '/xmltv.xml')
        channels = []
        for el in xmltv.findall('channel'):
            c_id = el.get('id')
            for sub_el in el.findall('display-name'):
                try:
                    c_num = int(sub_el.text)
                except (ValueError):
                    continue
            channels.append((c_num, c_id ))

        xmltv_ch = {}
        programmes = xmltv.findall("programme")
        for el in channels:
            programme = Element("tv")
            for pro in programmes:
                #print el[1] + ' : ' + pro.get('channel')
                if el[1] == pro.get('channel'):
                    programme.append(pro)
            xmltv_ch[str(el[0])] = programme

        # for k,v in xmltv_ch.items():
        #     print k,v
        #     fd = open("/home/mc/ww/" + str(k) + ".xml", "w")
        #     ElementTree(v).write(fd, 'utf-8')
        #     fd.close()

        for xml_file in glob(DIR_EPG + '/[0-9]*.xml'):

            tree = ElementTree()
            try:
                tree.parse(xml_file)
            except (SyntaxError):
                continue

            xmltv = xmltv_ch.get(os.path.splitext(os.path.basename(xml_file))[0])
            if xmltv == None:
                continue

            for el in tree.findall("programme"):
                start_epgdump = el.get('start')
                for el2 in xmltv.findall("programme"):
                    start_xmltv = el2.get('start')
                    if start_epgdump == start_xmltv:
                        el.remove(el.find('title'))
                        ti = el2.find('title')
                        ti.set('lang', 'ja_JP')
                        el.insert(0, ti)
                        credits = el2.find('credits')
                        if credits != None:
                            el.append(credits)

            fd = open(DIR_EPG + '/' + os.path.basename(xml_file), "w")
            tree.write(fd, 'utf-8')
            fd.close()
