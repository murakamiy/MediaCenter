# -*- coding: utf-8 -*-
import sys
import os
import os.path
import string
import re
from glob import glob
from datetime import datetime
import time
from xml.etree.cElementTree import ElementTree
from xml.etree.cElementTree import Element
from constant import *

DIR_EPG = os.environ["MC_DIR_EPG"]
DIR_TS = os.environ["MC_DIR_TS"]
DIR_RESERVED = os.environ["MC_DIR_RESERVED"]
DIR_RECORDING = os.environ["MC_DIR_RECORDING"]
DIR_FINISHED = os.environ["MC_DIR_RECORD_FINISHED"]
DIR_FAILED = os.environ["MC_DIR_FAILED"]
DIR_DISLIKE = os.environ["MC_DIR_DISLIKE"]
DIR_FAVORITE = os.environ["MC_DIR_FAVORITE"]
DIR_REMOVED = os.environ["MC_DIR_REMOVED"]
FILE_CHANNEL = os.environ["MC_FILE_CHANNEL"]
BIN_DO_JOB = os.environ["MC_BIN_DO_JOB"]
LOG_FILE = os.environ["MC_FILE_LOG"]
RESERVE_SPAN = 60 * 60 * 30 #30hours

class ProgramInfo:
    def __init__(self, el, now):
        self.start = datetime.strptime(string.split(el.get('start'))[0], '%Y%m%d%H%M%S')
        self.epoch_start = int(time.mktime(self.start.timetuple()))
        self.now = now
        self.epoch_now = int(time.mktime(self.now.timetuple()))
    def is_past_program(self):
        return self.epoch_start < self.epoch_now 
    def is_in_reserve_span(self):
        if self.is_past_program():
            return False
        return (self.epoch_start - self.epoch_now) <= RESERVE_SPAN
    def set_program_info(self, el):
        self.end   = datetime.strptime(string.split(el.get('stop'))[0],  '%Y%m%d%H%M%S')
        self.epoch_end = int(time.mktime(self.end.timetuple()))
        self.channel = self.get_text(el.get('channel'))
        self.title = self.get_text(el.find('title').text)
        self.desc = self.get_text(el.find('desc').text)
        self.rectime = self.epoch_end - self.epoch_start - 10
        self.category_1 = ''
        self.category_2 = ''
        i = 0
        for c in el.findall('category'):
            if i == 0:
                self.category_1 = self.get_text(c.text)
            elif i == 1:
                self.category_2 = self.get_text(c.text)
            i += 1
    def set_reserve_info(self):
        self.time_start = self.start.strftime("%Y/%m/%d %H:%M:%S")
        self.time_end = self.end.strftime("%Y/%m/%d %H:%M:%S")
        self.file_base = self.start.strftime("%Y%m%d-%H%M-") + self.channel
        self.file_ts = os.path.join(DIR_TS, self.file_base + ".ts")
        self.file_reserved = os.path.join(DIR_RESERVED, self.file_base + ".xml")
    def get_text(self, text):
        return text.encode('utf-8') if text != None else ""

class ReserveInfo:
    def __init__(self, pinfo, element, at_command=None):
        self.pinfo = pinfo
        self.element = element
        self.at_command = at_command

class ChannelSleepTime:
    def __init__(self):
        fd = open(FILE_CHANNEL)
        channel_list = fd.readlines()
        fd.close()
        sleep = 0
        self.channel_map = {}
        for c in channel_list:
            self.channel_map[c.rstrip()] = str(sleep)
            sleep += 5
    def get(self, channel):
        return self.channel_map.get(channel, "0")

def timeline_sort(x, y):
    ret = x.pinfo.epoch_start - y.pinfo.epoch_start
    if ret == 0:
        ret = x.pinfo.epoch_end - y.pinfo.epoch_end
    if ret < 0:
        ret = -1
    elif ret > 0:
        ret = 1
    return ret
def priority_sort(x, y):
    ret = y.pinfo.priority - x.pinfo.priority
    if ret == 0:
        ret = x.pinfo.epoch_start - y.pinfo.epoch_start
    if ret == 0:
        ret = x.pinfo.epoch_end - y.pinfo.epoch_end
    if ret == 0:
        ret = int(x.pinfo.channel) - int(y.pinfo.channel)
    if ret < 0:
        ret = -1
    elif ret > 0:
        ret = 1
    return ret

class ReserveMaker:
    def __init__(self, finder):
        self.finder = finder
        self.sleep = ChannelSleepTime()
        self.now = datetime.today()
        self.logfd = open(LOG_FILE, "a")
        self.title_sub_list = self.create_title_sub_list()
    def create_title_sub_list(self):
        str_list = [
            u'「.+」',
            u'（.+）',
            u'＜.+＞',
            u'【.+】',
            u'\[.+\]',
            u'\(.+\)',
            u'<.+>',
            u'#[0-9]+',
            ]
        pattern_list = []
        for s in str_list:
            pattern_list.append(re.compile(s))
        return pattern_list
    def log(self, message):
        print >> self.logfd, "%s\t%s\treserve.py" % (time.strftime("%H:%M:%S"), message)
        print "%s" % (message)
    def reserve(self):
        rinfo_list = []
        for xml_file in glob(DIR_EPG + '/[0-9]*.xml'):
            tree = self.parse_xml(xml_file)
            if tree == None:
                continue
            rinfo_list.extend(self.find(tree))
        rinfo_list.sort(cmp=timeline_sort, reverse=False)
        rinfo_list = self.apply_dislike(rinfo_list)
        rinfo_list = self.apply_favorite(rinfo_list)
        rinfo_list = self.apply_priority(rinfo_list)
        rinfo_list = self.create_reserve(rinfo_list)
        self.do_reserve(rinfo_list)
    def apply_dislike(self, rinfo_list):
        dislike_list = self.create_program_list(DIR_DISLIKE)
        self.log("dislike: ")
        for f in dislike_list:
            self.log(" %s" % f.title)
        return self.modify_priority(rinfo_list, dislike_list, -10)
    def apply_favorite(self, rinfo_list):
        favorite_list = self.create_program_list(DIR_FAVORITE)
        self.log("favorite: ")
        for f in favorite_list:
            self.log(" %s" % f.title)
        return self.modify_priority(rinfo_list, favorite_list, 15)
    def modify_priority(self, rinfo_list, modify_list, modifier):
        for rinfo in rinfo_list:
            for pinfo in modify_list:
                if rinfo.pinfo.channel == pinfo.channel and rinfo.pinfo.category_1 == pinfo.category_1 and re.search(pinfo.title_pattern, rinfo.pinfo.title):
                    rinfo.pinfo.priority += modifier
                    self.log(" %s %3d %2d %d %s" % (rinfo.pinfo.start, rinfo.pinfo.rectime / 60, int(rinfo.pinfo.channel), rinfo.pinfo.priority, rinfo.pinfo.title))
        return rinfo_list
    def create_program_list(self, dir):
        plist = []
        for xml_file in glob(dir + '/*.xml'):
            tree = self.parse_xml(xml_file)
            el = tree.find("programme")
            pinfo = ProgramInfo(el, self.now)
            pinfo.set_program_info(el)
            title = pinfo.title.decode('utf-8')
            for pattern in self.title_sub_list:
                title = re.sub(pattern, '', title)
            pinfo.title = title.encode('utf-8')
            pinfo.title_pattern = re.compile(re.escape(pinfo.title))
            plist.append(pinfo)
        return plist
    def apply_priority(self, rinfo_list):
        timer_list = self.create_timer(rinfo_list)
        job_list = []
        remove_list = []
        for time in timer_list:
            job_list = self.remove_end_job(job_list, time)
            job_list = self.append_start_job(rinfo_list, job_list, time)
            if len(job_list) > 2:
                job_list.sort(cmp=priority_sort, reverse=False)
                remove_list.extend(job_list[2:len(job_list)])
                job_list = job_list[0:2]
        self.log("removed: ")
        for r in remove_list:
            self.log(" %s %3d %2d %d %s" % (r.pinfo.start, r.pinfo.rectime / 60, int(r.pinfo.channel), r.pinfo.priority, r.pinfo.title))
            fd = open(DIR_REMOVED + '/' + r.pinfo.title + '.txt', "w")
            print >> fd, "%s %s %3d %2d %d %s" % (time.strftime("%H:%M:%S"), r.pinfo.start, r.pinfo.rectime / 60, int(r.pinfo.channel), r.pinfo.priority, r.pinfo.title)
            fd.close()
            try:
                rinfo_list.remove(r)
            except ValueError:
                pass
        return rinfo_list
    def remove_end_job(self, job_list, time):
        work_list = []
        for job in job_list:
            if job.pinfo.end != time:
                work_list.append(job)
        return work_list
    def append_start_job(self, rinfo_list, job_list, time):
        for rinfo in rinfo_list:
            if rinfo.pinfo.start == time:
                job_list.append(rinfo)
        return job_list
    def create_timer(self, rinfo_list):
        buf_1 = []
        for rinfo in rinfo_list:
            buf_1.append(rinfo.pinfo.start)
            buf_1.append(rinfo.pinfo.end)
        buf_1.sort()
        buf_2 = []
        for b in buf_1:
            if len(buf_2) == 0 or buf_2[-1] != b:
                buf_2.append(b)
        return buf_2
    def find(self, tree):
        rinfo_list = []
        for el in tree.findall("programme"):
            pinfo = ProgramInfo(el, self.now)
            if not pinfo.is_in_reserve_span():
                continue
            pinfo.set_program_info(el)
            pinfo = self.finder.like(pinfo)
            if pinfo == None:
                continue
            pinfo.set_reserve_info()
            rinfo_list.append(ReserveInfo(pinfo, el))
        return rinfo_list
    def do_reserve(self, rinfo_list):
        self.log("reserved:")
        for r in rinfo_list:
            if not os.path.exists(r.pinfo.file_reserved):
                os.system(r.at_command)
            fd = open(r.pinfo.file_reserved, "w")
            ElementTree(r.element).write(fd, 'utf-8')
            fd.close()
            self.log(" %s %3d %2d %d %s" % (r.pinfo.start, r.pinfo.rectime / 60, int(r.pinfo.channel), r.pinfo.priority, r.pinfo.title))
    def parse_xml(self, xml_file):
        tree = ElementTree()
        try:
            tree.parse(xml_file)
        except (SyntaxError):
            self.log("parse failed %s" % (xml_file))
            return None
        return tree
    def create_reserve(self, rinfo_list):
        new_list = []
        for r in rinfo_list:
            new_list.append(self.do_create_reserve(r.pinfo, r.element))
        return new_list
    def do_create_reserve(self, pinfo, el):
        rec_command = "rec %s %d %s" % (pinfo.channel, pinfo.rectime, pinfo.file_ts)
        do_job_command = "bash %s %s" % (BIN_DO_JOB, pinfo.file_base)
        at_command = "at -t %s > /dev/null 2>&1" % (pinfo.start.strftime("%Y%m%d%H%M"))

        attr = {"type" : "start"}
        epoch_start_element = Element("epoch", attr)
        epoch_start_element.text = str(pinfo.epoch_start)
        attr = {"type" : "stop"}
        epoch_stop_element = Element("epoch", attr)
        epoch_stop_element.text = str(pinfo.epoch_end)
        attr = {"type" : "start"}
        time_start_element = Element("time", attr)
        time_start_element.text = pinfo.time_start
        attr = {"type" : "stop"}
        time_stop_element = Element("time", attr)
        time_stop_element.text = pinfo.time_end

        found_by_element = Element("foundby")
        found_by_element.text = pinfo.found_by
        priority_element = Element("priority")
        priority_element.text = str(pinfo.priority)
        sleep_element = Element("sleep")
        sleep_element.text = self.sleep.get(pinfo.channel)
        do_job_element = Element("dojob")
        do_job_element.text = do_job_command
        at_element = Element("at")
        at_element.text = at_command
        rec_element = Element("rec")
        rec_element.text = rec_command

        command_element = Element("command")
        command_element.append(do_job_element)
        command_element.append(at_element)
        command_element.append(rec_element)

        reserved_element = Element("record")
        reserved_element.append(el)
        reserved_element.append(priority_element)
        reserved_element.append(found_by_element)
        reserved_element.append(sleep_element)
        reserved_element.append(time_start_element)
        reserved_element.append(time_stop_element)
        reserved_element.append(epoch_start_element)
        reserved_element.append(epoch_stop_element)
        reserved_element.append(command_element)
        return ReserveInfo(pinfo, reserved_element, "echo '%s' | %s" % (do_job_command, at_command))
