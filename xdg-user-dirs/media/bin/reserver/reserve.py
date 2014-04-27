# -*- coding: utf-8 -*-
import sys
import os
import os.path
import string
import re
from glob import glob
from datetime import datetime
from datetime import timedelta
from dateutil import rrule
import time
import random
from xml.etree.cElementTree import ElementTree
from xml.etree.cElementTree import Element
import unicodedata
from rating import rating

DIR_EPG = os.environ["MC_DIR_EPG"]
DIR_TS = os.environ["MC_DIR_TS"]
DIR_RESERVED = os.environ["MC_DIR_RESERVED"]
DIR_REMOVED = os.environ["MC_DIR_REMOVED"]
BIN_DO_JOB = os.environ["MC_BIN_DO_JOB"]
LOG_FILE = os.environ["MC_FILE_LOG"]
CRON_TIME = os.environ["MC_CRON_TIME"]

class ProgramInfo:
    def __init__(self, el, now, next_cron):
        self.now = now
        self.next_cron = next_cron
        self.start = datetime.strptime(string.split(el.get('start'))[0], '%Y%m%d%H%M%S')
        self.epoch_start = int(time.mktime(self.start.timetuple()))
        self.channel = self.get_text(el.get('channel'))
        self.priority = random.choice((1, 2, 3))
        self.found_by = "Random"
    def is_in_reserve_span(self):
        if self.now < self.start and self.start < self.next_cron:
            return True
        return False
    def set_program_info(self, el):
        self.element = el
        self.end   = datetime.strptime(string.split(el.get('stop'))[0],  '%Y%m%d%H%M%S')
        self.epoch_end = int(time.mktime(self.end.timetuple()))
        self.title = self.get_text(el.find('title').text)
        self.desc = self.get_text(el.find('desc').text)
        self.rectime = self.epoch_end - self.epoch_start
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
        ch = self.get_text(self.element.get('channel'))
        if re.search('^BS_', ch):
            self.broadcasting = 'BS'
        elif re.search('^CS_', ch):
            self.broadcasting = 'CS'
        else:
            self.broadcasting = 'Digital'
    def get_text(self, text):
        return text.encode('utf-8') if text != None else ""

class ReserveInfo:
    def __init__(self, pinfo, element, at_command=None):
        self.pinfo = pinfo
        self.element = element
        self.at_command = at_command

def timeline_sort(x, y):
    ret = x.pinfo.epoch_start - y.pinfo.epoch_start
    if ret == 0:
        ret = x.pinfo.epoch_end - y.pinfo.epoch_end
    if ret < 0:
        ret = -1
    elif ret > 0:
        ret = 1
    return ret
def timeline_channel_sort(x, y):
    ret = x.pinfo.epoch_start - y.pinfo.epoch_start
    if ret == 0:
        if x.pinfo.channel == y.pinfo.channel:
            ret = x.pinfo.epoch_end - y.pinfo.epoch_end
        elif x.pinfo.channel < y.pinfo.channel:
            ret = 1
        else:
            ret = -1
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
    if ret < 0:
        ret = -1
    elif ret > 0:
        ret = 1
    return ret

class ReserveMaker:
    def __init__(self, finder):
        self.finder = finder
        self.now = datetime.now()
        one_minute = timedelta(0, 60, 0)
        self.now += one_minute
        self.logfd = open(LOG_FILE, "a")
        self.include_channel = None
        cron = map(int, CRON_TIME.split(":"))
        rule = rrule.rrule(rrule.DAILY,
                dtstart=datetime(self.now.year, self.now.month, self.now.day, cron[0], cron[1], cron[2]))
        self.next_cron = rule.after(self.now)
    def log(self, message):
        print >> self.logfd, "%s\t%s\treserve.py" % (time.strftime("%H:%M:%S"), message)
        print "%s" % (message)
    def reserve(self, xml_glob_list):
        rinfo_set = []
        for xml_glob in xml_glob_list:
            rinfo_list = []
            tree_list = []
            for xml_file in glob(DIR_EPG + '/' + xml_glob):
                tree = self.parse_xml(xml_file)
                if tree == None:
                    continue
                rinfo_list.extend(self.find(tree))
                tree_list.append(tree)
            rinfo_list.sort(cmp=timeline_sort, reverse=False)
            rinfo_list = self.apply_rating(rinfo_list)
            rinfo_list = self.apply_priority(rinfo_list, True)
            rinfo_set.append([tree_list, rinfo_list])

        span_list = self.create_span(rinfo_set)

        bcas_list = []
        for rset in rinfo_set:
            tree_list = rset[0]
            rinfo_list = rset[1]
            rinfo_list.extend(self.find_span(rinfo_list, span_list, tree_list))
            rinfo_list = self.apply_priority(rinfo_list, False)
            bcas_list.extend(rinfo_list)

        bcas_list.sort(cmp=timeline_channel_sort, reverse=False)


#         self.log("reserved:")
#         for r in bcas_list:
#             self.log(" %s %s %6s %5.1f %s" % (r.pinfo.start.strftime('%d %H:%M'), r.pinfo.end.strftime('%H:%M'), r.pinfo.channel, r.pinfo.priority, r.pinfo.title))


        bcas_list = self.create_reserve(bcas_list)
        self.do_reserve(bcas_list)

    def apply_rating(self, rinfo_list):
        provider = rating.Provider()
        for rinfo in rinfo_list:
            rating_v = provider.get_rating_element(rinfo.pinfo.element)
            rinfo.pinfo.priority = rinfo.pinfo.priority + (rating_v * 10)
        return rinfo_list
    def get_lower_priority_list(self, rinfo_list):
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
        return remove_list
    def apply_priority(self, rinfo_list, do_print):
        remove_list = self.get_lower_priority_list(rinfo_list)
        remove_list.sort(cmp=timeline_sort, reverse=False)
        if do_print:
            self.log("removed: ")
        for r in remove_list:
            if do_print:
                self.log(" %s %s %6s %5.1f %s" % (r.pinfo.start.strftime('%d %H:%M'), r.pinfo.end.strftime('%H:%M'), r.pinfo.channel, r.pinfo.priority, r.pinfo.title))
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
    def create_span(self, rinfo_set):
        span_list = []
        for rset in rinfo_set:
            rinfo_list = rset[1]
            buf_1 = []
            for rinfo in rinfo_list:
                buf_1.append((rinfo.pinfo.start, rinfo.pinfo.end))
            span_list.extend(buf_1)
        span_list.sort()
        span_list_2 = []
        for s in span_list:
            if len(span_list_2) == 0 or span_list_2[-1] != s:
                span_list_2.append(s)
        span_list_m = []
        cur = None
        prev = None
        merge = None
        for cur in span_list_2:
            if merge != None:
                if merge[1] >= cur[0]:
                    merge = (merge[0], max(merge[1], cur[1]))
                else:
                    span_list_m.append(merge)
                    merge = None
            else:
                if prev != None:
                    if prev[1] >= cur[0]:
                        merge = (prev[0], max(prev[1], cur[1]))
                    else:
                        span_list_m.append(prev)
            prev = cur
        if merge != None:
            span_list_m.append(merge)
        if span_list_m[-1][1] < cur[1]:
            span_list_m.append(cur)
        self.log("span_list:")
        for s in span_list_m:
            self.log(" %s %s" % (s[0].strftime('%Y/%m/%d %H:%M'), s[1].strftime('%Y/%m/%d %H:%M')))
        return span_list_m
    def set_include_channel(self, channel):
        self.include_channel = channel
    def is_include_channel(self, pinfo):
        if self.include_channel == None:
            return True
        return pinfo.channel in self.include_channel
    def find(self, tree):
        rinfo_list = []
        for el in tree.findall("programme"):
            pinfo = ProgramInfo(el, self.now, self.next_cron)
            if not pinfo.is_in_reserve_span():
                continue
            if not self.is_include_channel(pinfo):
                continue
            pinfo.set_program_info(el)
            pinfo = self.finder.like(pinfo)
            if pinfo == None:
                continue
            pinfo.set_reserve_info()
            rinfo_list.append(ReserveInfo(pinfo, el))
        return rinfo_list
    def find_span(self, rinfo_list, span_list, tree_list):
        found_list = []
        for tree in tree_list:
            for el in tree.findall("programme"):
                pinfo = ProgramInfo(el, self.now, self.next_cron)
                if not pinfo.is_in_reserve_span():
                    continue
                if not self.is_include_channel(pinfo):
                    continue
                pinfo.set_program_info(el)

                for span in span_list:
                    if span[0] <= pinfo.start and pinfo.end <= span[1]:
                        allready_reserved = False
                        for rinfo in rinfo_list:
                            if rinfo.pinfo.channel == pinfo.channel and rinfo.pinfo.start == pinfo.start:
                                allready_reserved = True
                        if allready_reserved == False and pinfo.rectime > (60 * 20) and pinfo.title != "放送休止":
                            pinfo.set_reserve_info()
                            found_list.append(ReserveInfo(pinfo, el))
#         self.log("find_span:")
#         for r in found_list:
#             self.log(" %s %s %6s %5.1f %s" % (r.pinfo.start.strftime('%d %H:%M'), r.pinfo.end.strftime('%H:%M'), r.pinfo.channel, r.pinfo.priority, r.pinfo.title))
        return found_list
    def do_reserve(self, rinfo_list):
        self.log("reserved:")
        for r in rinfo_list:
            if not os.path.exists(r.pinfo.file_reserved):
                os.system(r.at_command)
            fd = open(r.pinfo.file_reserved, "w")
            ElementTree(r.element).write(fd, 'utf-8')
            fd.close()
            self.log(" %s %s %6s %5.1f %s" % (r.pinfo.start.strftime('%d %H:%M'), r.pinfo.end.strftime('%H:%M'), r.pinfo.channel, r.pinfo.priority, r.pinfo.title))
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
        rec_command = "rec %s %d %s" % (pinfo.channel, pinfo.rectime - 10, pinfo.file_ts)
        do_job_command = "exec bash %s %s" % (BIN_DO_JOB, pinfo.file_base)
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

        broadcasting_element = Element("broadcasting")
        broadcasting_element.text = pinfo.broadcasting
        found_by_element = Element("foundby")
        found_by_element.text = pinfo.found_by
        priority_element = Element("priority")
        priority_element.text = str(pinfo.priority)
        do_job_element = Element("dojob")
        do_job_element.text = do_job_command
        at_element = Element("at")
        at_element.text = at_command
        rec_element = Element("rec")
        rec_element.text = rec_command
        rec_channel_element = Element("rec-channel")
        rec_channel_element.text = pinfo.channel
        rec_time_element = Element("rec-time")
        rec_time_element.text = str(pinfo.rectime - 10)

        command_element = Element("command")
        command_element.append(do_job_element)
        command_element.append(at_element)
        command_element.append(rec_element)

        reserved_element = Element("record")
        reserved_element.append(el)
        reserved_element.append(priority_element)
        reserved_element.append(found_by_element)
        reserved_element.append(broadcasting_element)
        reserved_element.append(time_start_element)
        reserved_element.append(time_stop_element)
        reserved_element.append(epoch_start_element)
        reserved_element.append(epoch_stop_element)
        reserved_element.append(rec_channel_element)
        reserved_element.append(rec_time_element)
        reserved_element.append(command_element)
        return ReserveInfo(pinfo, reserved_element, "echo '%s' | %s" % (do_job_command, at_command))
