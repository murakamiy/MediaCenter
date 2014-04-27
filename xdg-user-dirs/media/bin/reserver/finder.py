# -*- coding: utf-8 -*-
import re
import random
import os
from datetime import datetime
from datetime import time

CRON_TIME = os.environ["MC_CRON_TIME"]
cron_arr = map(int, CRON_TIME.split(":"))
cron_time = time(cron_arr[0], cron_arr[1], cron_arr[2])


class FindresCheif:
    finders = []
    def __init__(self, finders):
        self.finders = finders
    def like(self, pinfo):
        found_by = None
        for f in self.finders:
            if f.like(pinfo):
                if found_by == None or found_by.how_much_like() < f.how_much_like():
                    found_by = f
        if found_by == None:
            return None
        else:
            pinfo.priority = found_by.how_much_like()
            pinfo.found_by = found_by.__class__.__name__
            return pinfo

class Finder:
    priority = 50
    allow_list = None
    deny_list = None
    allow_pattern = None
    deny_pattern = None
    def __init__(self):
        if self.allow_list != None and len(self.allow_list) > 0:
            self.allow_pattern = self.create_pattern(self.allow_list)
        if self.deny_list != None and len(self.deny_list) > 0:
            self.deny_pattern = self.create_pattern(self.deny_list)
    def create_pattern(self, plist):
        buf = ''
        for s in plist[0:-1]:
            buf += re.escape(s.encode('utf-8')) + '|'
        buf = '(' + buf + re.escape(plist[-1].encode('utf-8')) + ')'
        return re.compile(buf)
    def like(self, pinfo):
        if pinfo.rectime > (60 * 60 * 6):
            return False
        if pinfo.rectime < (60 * 20):
            return False
        if pinfo.start.hour <= cron_time.hour and cron_time.hour <= pinfo.end.hour:
            return False
        return self.allow(pinfo)
    def allow(self, pinfo):
        raise NotImplementedError('abstract method')
    def how_much_like(self):
        return self.priority

####################################################################################################
####################################################################################################

class NewsFinder(Finder):
    priority = 1
    def allow(self, pinfo):
        if pinfo.category_1 == 'ニュース／報道':
            return True
        return False

class AnimeFinder(Finder):
    priority = 50
    deny_list = [
        u'アスタロッテのおもちゃ',
        u'オー!マイキー',
        u'蒼天航路',
        u'タイムボカン',
        u'世界一初恋',
        u'日常',
        u'TIGER&BUNNY',
        u'戦国乙女',
        u'DOG　DAYS',
        u'ワンピース',
        u'デジタルリマスターHD版',
        u'銀魂',
        u'ベルサイユのばら',
        u'コレクター・ユイ',
        u'トリコ',
    ]
    def allow(self, pinfo):
        if pinfo.category_1 == 'アニメ／特撮' and pinfo.category_2 == '国内アニメ' and (pinfo.start.hour >= 23 or pinfo.start.hour <= 4):
            if not re.search(self.deny_pattern, pinfo.title):
                if pinfo.channel != 'CS_331':
                    return True
        return False

class BoxingFinder(Finder):
    priority = 10
    allow_list = [
        u'ボクシング',
        u'エキサイトマッチ',
    ]
    def allow(self, pinfo):
        if re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class TitleFinder(Finder):
    priority = 100
    allow_list = [
        u'NARUTO',
        u'はじめの一歩',
        u'ベストヒットUSA',
        u'夏目友人帳',
        u'Kanon',
        u'ジョジョの奇妙な冒険',
        u'頭文字D',
        u'花咲舞が黙ってない',
    ]
    def allow(self, pinfo):
        if re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class CreditFinderHigh(Finder):
    priority = 100
    allow_list = [
        u'西尾維新',
    ]
    deny_list = [
        u'BSプレマップ',
    ]
    def allow(self, pinfo):
        if not re.search(self.deny_pattern, pinfo.title) and re.search(self.allow_pattern, pinfo.desc):
            return True
        return False

class CreditFinder(Finder):
    priority = 40
    allow_list = [
        u'YUI',
        u'麻枝准',
    ]
    deny_list = [
        u'BSプレマップ',
    ]
    def allow(self, pinfo):
        if not re.search(self.deny_pattern, pinfo.title) and re.search(self.allow_pattern, pinfo.desc):
            return True
        return False

class F1Finder(Finder):
    priority = 40
    allow_list = [
        u'F1',
        u'WRC',
    ]
    def allow(self, pinfo):
        if pinfo.category_2 == 'モータースポーツ' and re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class VarietyFinder(Finder):
    priority = 40
    allow_list = [
        u'リンカーン',
        u'ダウンタウンのガキの使いやあらへんで',
        u'とんねるずのみなさんのおかげでした',
        u'さんまのスーパーからくりTV',
    ]
    def allow(self, pinfo):
        if pinfo.category_1 == 'バラエティ':
            if re.search(self.allow_pattern, pinfo.title):
                return True
            if re.search(self.allow_pattern, pinfo.desc):
                return True
        return False

class MovieFinder(Finder):
    priority = 70
    random_channel = random.choice(('BS_200','BS_193','CS_227','CS_240'))
    random_hour = random.choice((20,21))
    rectime = 60 * 90
    reserved = False
    def allow(self, pinfo):
        if self.reserved == False and \
           pinfo.channel == self.random_channel and \
           self.rectime < pinfo.rectime and \
           (pinfo.start.hour == self.random_hour or pinfo.start.hour == self.random_hour + 1):
            self.reserved = True
            return True 
        return False

####################################################################################################
# ProgramInfo
####################################################################################################
# start        =  datetime.strptime(string.split(el.get('start'))[0],  '%Y%m%d%H%M%S')
# epoch_start  =  int(time.mktime(self.start.timetuple()))
# now          =  now
# epoch_now    =  int(time.mktime(self.now.timetuple()))
# end          =  datetime.strptime(string.split(el.get('stop'))[0],   '%Y%m%d%H%M%S')
# epoch_end    =  int(time.mktime(self.end.timetuple()))
# title        =  self.get_text(el.find('title').text)
# desc         =  self.get_text(el.find('desc').text)
# category_1   =  i = 0 for c in el.findall('category'): if i == 0: self.category_1 = self.get_text(c.text)
# category_2   =  i = 0 for c in el.findall('category'): elif i == 1: self.category_2 = self.get_text(c.text)
# priority     = found_by.how_much_like()
# found_by     = found_by.__class__.__name__
# rectime      = self.epoch_end - self.epoch_start - 10
# channel      = self.get_text(el.get('channel'))
