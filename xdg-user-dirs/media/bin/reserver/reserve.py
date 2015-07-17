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
from xml.etree.cElementTree import ElementTree
from xml.etree.cElementTree import Element
import unicodedata
from rating import rating

DIR_EPG = os.environ["MC_DIR_EPG"]
DIR_TS = os.environ["MC_DIR_TS"]
DIR_RESERVED = os.environ["MC_DIR_RESERVED"]
DIR_RRD = os.environ["MC_DIR_RRD"]
DIR_ENCODE = os.environ["MC_DIR_ENCODE_RESERVED"]
BIN_DO_JOB = os.environ["MC_BIN_DO_JOB"]
BIN_ENCODE = os.environ["MC_BIN_ENCODE"]
LOG_FILE = os.environ["MC_FILE_LOG"]
CRON_TIME = os.environ["MC_CRON_TIME"]

class ProgramInfo:
    def __init__(self, el, now, border_time):
        self.is_reserved = False
        self.now = now
        self.border_time = border_time
        self.start = datetime.strptime(string.split(el.get('start'))[0], '%Y%m%d%H%M%S')
        self.epoch_start = int(time.mktime(self.start.timetuple()))
        self.channel = self.get_text(el.get('channel'))
        self.priority = 0
        self.found_by = "CatchAll"
    def is_in_reserve_span(self):
        if self.now < self.start and self.start < self.border_time:
            return True
        return False
    def set_program_info(self, el):
        self.element = el
        self.end   = datetime.strptime(string.split(el.get('stop'))[0],  '%Y%m%d%H%M%S')
        self.epoch_end = int(time.mktime(self.end.timetuple()))
        self.title = self.get_text(el.find('title').text)
        self.desc = self.get_text(el.find('desc').text)
        self.rectime = self.epoch_end - self.epoch_start
        self.category_list = []
        for c in el.findall('category'):
            self.category_list.append(self.get_text(c.text))
        ch = self.get_text(self.element.get('channel'))
        if re.search('^BS_', ch):
            self.broadcasting = 'BS'
        elif re.search('^CS_', ch):
            self.broadcasting = 'CS'
        else:
            self.broadcasting = 'Digital'
    def set_reserve_info(self):
        self.is_reserved = True
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
    def __init__(self, finder, random_finder, dry_run):
        self.finder = finder
        self.random_finder = random_finder
        self.now = datetime.now()
        five_minute = timedelta(0, 60 * 5, 0)
        self.now += five_minute
        self.logfd = open(LOG_FILE, "a")
        self.dry_run = dry_run
        self.include_channel = None
        self.exclude_channel = None
        cron = map(int, CRON_TIME.split(":"))
        rule = rrule.rrule(rrule.DAILY,
                dtstart=datetime(self.now.year, self.now.month, self.now.day, cron[0], cron[1], cron[2]))
        self.next_cron = rule.after(self.now)
        self.random_finder.cron_hour = cron[0]
        self.random_finder.next_cron = self.next_cron
        if self.dry_run == True:
            self.border_time = self.now + timedelta(1, 0, 0)
        else:
            self.border_time = self.next_cron + timedelta(0, finder.finders[0].rectime_max, 0)
        self.provider = rating.Provider()
    def log(self, message):
        if self.dry_run == False:
            print >> self.logfd, "%s\t%s\treserve.py" % (time.strftime("%H:%M:%S"), message)
        print "%s" % (message)
    def rating_log(self, pinfo, rating_v):
        self.log(" %s %s %6s %+3d %s %s" %
                    (
                        pinfo.start.strftime('%d %H:%M'),
                        pinfo.end.strftime('%H:%M'),
                        pinfo.channel,
                        rating_v,
                        pinfo.found_by[0:3],
                        pinfo.title
                    )
                )
    def reserve_log(self, pinfo):
        self.log(" %s %s %6s %3d %s %s" %
                    (
                        pinfo.start.strftime('%d %H:%M'),
                        pinfo.end.strftime('%H:%M'),
                        pinfo.channel,
                        pinfo.priority,
                        pinfo.found_by[0:3],
                        pinfo.title
                    )
                )
    def reserve(self, xml_glob_list):
        isdb_prog_list = [] # [isdb-t-program, isdb-s-program]
        for xml_glob in xml_glob_list:
            prog_list = []
            for xml_file in glob(DIR_EPG + '/' + xml_glob):
                tree = self.parse_xml(xml_file)
                if tree == None:
                    continue
                prog_list.extend(self.create_program_list(tree))
            prog_list = self.remove_duplication(prog_list)
            isdb_prog_list.append(prog_list)

        title_list = []
        isdb_set = [] # [(isdb-t-program, isdb-t-reserve), (isdb-s-program, isdb-s-reserve)]
        for prog_list in isdb_prog_list:
            rinfo_list = self.find(prog_list, title_list)
            rinfo_list.sort(cmp=timeline_sort, reverse=False)
            rinfo_list = self.apply_rating(rinfo_list)
            rinfo_list = self.apply_priority(rinfo_list, True)
            isdb_set.append((prog_list, rinfo_list))

        span_list = self.create_span(isdb_set)
        span_list = self.optimize_span(span_list)
        (span_list, encode_list) = self.reserve_encode(len(glob(DIR_ENCODE + '/' + '*.xml')), span_list)

        all_rinfo_list = []
        for isdb in isdb_set:
            prog_list = isdb[0]
            rinfo_list = isdb[1]
            if self.random_finder != None:
                random_list = self.find_random(span_list, prog_list, title_list)
                random_list = self.apply_rating(random_list)
                rinfo_list.extend(random_list)
                rinfo_list = self.apply_priority(rinfo_list, False)
            if self.dry_run == False:
                rinfo_list = self.remove_border_strech(rinfo_list)
                rinfo_list = self.remove_cron_span(rinfo_list)
            all_rinfo_list.extend(rinfo_list)

        all_rinfo_list.sort(cmp=timeline_channel_sort, reverse=False)
        if self.dry_run == False:
            self.update_rrd(all_rinfo_list, encode_list)
        all_rinfo_list = self.create_reserve(all_rinfo_list)
        self.do_reserve(all_rinfo_list)
        self.do_reserve_encode(encode_list)

    def remove_border_strech(self, rinfo_list):
        new_list = []
        for rinfo in rinfo_list:
            if rinfo.pinfo.start < self.next_cron:
                new_list.append(rinfo)
        return new_list
    def remove_cron_span(self, rinfo_list):
        remove_list = []
        new_list = []
        for rinfo in rinfo_list:
            if self.next_cron <= rinfo.pinfo.end:
                remove_list.append(rinfo)
            else:
                new_list.append(rinfo)
        if 0 < len(remove_list):
            remove_list.sort(cmp=priority_sort, reverse=False)
            new_list.append(remove_list[0])
        if 1 < len(remove_list):
            self.log("removed_cron: ")
            for r in remove_list[1:]:
                self.reserve_log(r.pinfo)
        return new_list
    def apply_rating(self, rinfo_list):
        self.log("apply_rating: ")
        for rinfo in rinfo_list:
            rating_v = self.provider.get_rating(rinfo.pinfo)
            rinfo.pinfo.priority += rating_v
            if rating_v != 0:
                self.rating_log(rinfo.pinfo, rating_v)
        return rinfo_list
    def apply_priority(self, rinfo_list, do_print):
        remove_list = self.simulate_recording(rinfo_list)
        remove_list.sort(cmp=timeline_sort, reverse=False)
        if do_print:
            self.log("removed: ")
        for r in remove_list:
            if do_print:
                self.reserve_log(r.pinfo)
            try:
                rinfo_list.remove(r)
            except ValueError:
                pass
        return rinfo_list
    def simulate_recording(self, rinfo_list):
        timeline = self.create_timeline(rinfo_list)
        recordings = []
        remove_list = []
        for now in timeline:
            recordings = self.stop_recording(recordings, now)
            recordings = self.start_recording(rinfo_list, recordings, now)
            if len(recordings) > 2:
                recordings.sort(cmp=priority_sort, reverse=False)
                remove_list.extend(recordings[2:])
                recordings = recordings[0:2]
        return remove_list
    def stop_recording(self, recordings, now):
        work_list = []
        for job in recordings:
            if job.pinfo.end != now:
                work_list.append(job)
        return work_list
    def start_recording(self, rinfo_list, recordings, now):
        for rinfo in rinfo_list:
            if rinfo.pinfo.start == now:
                recordings.append(rinfo)
        return recordings
    def create_timeline(self, rinfo_list):
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
        if span_list_m and cur:
            if span_list_m[-1][1] < cur[1]:
                span_list_m.append(cur)
        self.log("span_list:")
        for s in span_list_m:
            self.log(" %s %s" % (s[0].strftime('%Y/%m/%d %H:%M'), s[1].strftime('%Y/%m/%d %H:%M')))
        return span_list_m
    def optimize_span(self, span_list):
        if len(span_list) <= 1:
            return span_list

        span_list_l = []
        for s in span_list:
            span_list_l.append([s[0], s[1]])
        one_hour = timedelta(0, 60 * 59, 0)
        for s in span_list_l:
            s[0] -= timedelta(0, 60 * s[0].minute, 0)
            s[1] += one_hour
            s[1] -= timedelta(0, 60 * s[1].minute, 0)
        thirty_minute = timedelta(0, 60 * 30, 0)
        for i in xrange(0, len(span_list_l) - 1):
            after = span_list_l[i + 1][0] - span_list_l[i][1]
            if after < thirty_minute:
                span_list_l[i][1] = span_list_l[i + 1][1]
                span_list_l[i + 1][0] = span_list_l[i][0]
        span_list_m = []
        for s in span_list_l:
            if s not in span_list_m:
                span_list_m.append(s)

        span_list_m2 = []
        for i in xrange(0, len(span_list_m) - 1):
            if span_list_m[i][0] != span_list_m[i + 1][0]:
                span_list_m2.append(span_list_m[i])
        if span_list_m[-1][0] != span_list_m2[-1][0]:
            span_list_m2.append(span_list_m[-1])

        self.log("span_list_optimized:")
        for s in span_list_m2:
            self.log(" %s %s" % (s[0].strftime('%Y/%m/%d %H:%M'), s[1].strftime('%Y/%m/%d %H:%M')))
        return span_list_m2
    def reserve_encode(self, count, span_list):
        encode_list = []
        if count == 0:
            return (span_list, encode_list)
        encode_time = timedelta(0, 60 * 60 * 3, 0)
        one_day = timedelta(1, 0, 0)
        while 0 < count:
            for s in span_list:
                if len(s) == 2 and encode_time <= s[1] - s[0] and s[1] - self.now < one_day:
                    encode_command = "exec bash %s" % (BIN_ENCODE)
                    at_command = "at -t %s > /dev/null 2>&1" % (s[0].strftime("%Y%m%d%H%M"))
                    s.append("echo '%s' | %s" % (encode_command, at_command))
                    break
            count -= 1
        span_list_ret = []
        for s in span_list:
            if len(s) == 2:
                span_list_ret.append(s)
            else:
                encode_list.append(s)
        self.log("span_list_modified:")
        for s in span_list_ret:
            self.log(" %s %s" % (s[0].strftime('%Y/%m/%d %H:%M'), s[1].strftime('%Y/%m/%d %H:%M')))
        return (span_list_ret, encode_list)
    def do_reserve_encode(self, encode_list):
        self.log("reserved encode:")
        for e in encode_list:
            if self.dry_run == False:
                os.system(e[2])
            self.log(" %s %s %s" %
                        (
                            e[0].strftime('%d %H:%M'),
                            e[1].strftime('%H:%M'),
                            "ENCODE_JOB"
                        )
                    )
    def set_dry_run(self, dry_run):
        self.dry_run = dry_run
    def set_include_channel(self, channel):
        self.include_channel = channel
    def set_exclude_channel(self, channel):
        self.exclude_channel = channel
    def is_include_channel(self, pinfo):
        if self.include_channel == None:
            is_include = True
        else:
            is_include = pinfo.channel in self.include_channel
        if self.exclude_channel == None:
            is_exclude = False
        else:
            is_exclude = pinfo.channel in self.exclude_channel
        return (is_include == True and is_exclude == False)
    def create_program_list(self, tree):
        prog_list = []
        for el in tree.findall("programme"):
            pinfo = ProgramInfo(el, self.now, self.border_time)
            if not pinfo.is_in_reserve_span():
                continue
            if not self.is_include_channel(pinfo):
                continue
            pinfo.set_program_info(el)
            prog_list.append(pinfo)
        return prog_list
    def remove_duplication(self, prog_list):
        new_prog_list = []
        self.log("duplicated: ")
        for pinfo in prog_list:
            ret = self.provider.has_same_record(pinfo.title.decode("utf-8"), pinfo.channel.decode("utf-8"), pinfo.epoch_start)
            if ret == True:
                self.reserve_log(pinfo)
            else:
                new_prog_list.append(pinfo)
        return new_prog_list
    def find(self, prog_list, title_list):
        rinfo_list = []
        self.log("duplicated find: ")
        for pinfo in prog_list:
            if pinfo.title in title_list:
                self.reserve_log(pinfo)
                continue
            pinfo = self.finder.like(pinfo)
            if pinfo == None:
                continue
            title_list.append(pinfo.title)
            pinfo.set_reserve_info()
            rinfo_list.append(ReserveInfo(pinfo, pinfo.element))
        return rinfo_list
    def find_random(self, span_list, prog_list, title_list):
        found_list = []
        self.log("duplicated find_random: ")
        for pinfo in prog_list:
            if pinfo.is_reserved == True:
                continue
            if self.is_in_span(span_list, pinfo) == False:
                continue
            if pinfo.title in title_list:
                self.reserve_log(pinfo)
                continue
            pinfo = self.random_finder.like(pinfo)
            if not pinfo:
                continue
            title_list.append(pinfo.title)
            pinfo.set_reserve_info()
            found_list.append(ReserveInfo(pinfo, pinfo.element))
        return found_list
    def is_in_span(self, span_list, pinfo):
        is_in = False
        for span in span_list:
            if span[0] <= pinfo.start and pinfo.end <= span[1]:
                is_in = True
                break
        return is_in
    def do_reserve(self, rinfo_list):
        self.log("reserved:")
        for r in rinfo_list:
            if not self.dry_run:
                if not os.path.exists(r.pinfo.file_reserved):
                    os.system(r.at_command)
                fd = open(r.pinfo.file_reserved, "w")
                ElementTree(r.element).write(fd, 'utf-8')
                fd.close()
            self.reserve_log(r.pinfo)
    def parse_xml(self, xml_file):
        tree = ElementTree()
        try:
            tree.parse(xml_file)
        except (SyntaxError):
            self.log("parse failed %s" % (xml_file))
            return None
        return tree
    def update_rrd(self, rinfo_list, encode_list):
        if not rinfo_list:
            return
        begin = None
        end = None
        for r in rinfo_list:
            if begin == None or begin > r.pinfo.start:
                begin = r.pinfo.start
            if end == None or end < r.pinfo.end:
                end = r.pinfo.end

        rrdfile = "/tmp/rrdupdate.sh"
        rrdfd = open(rrdfile, "w")
        one_minute = timedelta(0, 60, 0)
        now = begin
        i = 1
        buf = ""
        while now <= end:
            t_prefer = 0
            t_random = 0
            s_prefer = 0
            s_random = 0
            encode = 0
            for e in encode_list:
                if e[0] <= now and now < e[1]:
                    encode = 1
            for r in rinfo_list:
                if r.pinfo.start <= now and now < r.pinfo.end:
                    if r.pinfo.broadcasting == 'Digital':
                        if r.pinfo.found_by == 'RandomFinder':
                            t_random += 1
                        else:
                            t_prefer += 1
                    else:
                        if r.pinfo.found_by == 'RandomFinder':
                            s_random += 1
                        else:
                            s_prefer += 1

            buf += "'%s'@%d:%d:%d:%d:%d " % (
                    now.strftime("%Y%m%d %H:%M"),
                    t_prefer,
                    t_random,
                    s_prefer,
                    s_random,
                    encode)

            if i % 10 == 0:
                rrdfd.write("rrdtool update %s/rec.rrd %s\n" % (DIR_RRD, buf))
                buf = ""
            i += 1
            now += one_minute

        if buf != "":
            rrdfd.write("rrdtool update %s/rec.rrd %s\n" % (DIR_RRD, buf))

        rrdfd.close()
        ret = os.system("bash " + rrdfile)

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
        priority_element.text = "%.1f" % (pinfo.priority)
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

        original_file_element = Element("original-file")
        original_file_element.text = pinfo.original_file
        encode_width_element = Element("encode-width")
        encode_width_element.text = str(pinfo.encode_width)
        encode_height_element = Element("encode-height")
        encode_height_element.text = str(pinfo.encode_height)
        encode_bitrate_element = Element("encode-bitrate")
        encode_bitrate_element.text = pinfo.encode_bitrate

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

        reserved_element.append(original_file_element)
        reserved_element.append(encode_width_element)
        reserved_element.append(encode_height_element)
        reserved_element.append(encode_bitrate_element)

        return ReserveInfo(pinfo, reserved_element, "echo '%s' | %s" % (do_job_command, at_command))
