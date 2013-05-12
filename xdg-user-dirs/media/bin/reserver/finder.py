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
        if (pinfo.epoch_end - pinfo.epoch_start) > (60 * 60 * 3):
            return False
        if (
                (cron_time.hour == pinfo.start.hour and pinfo.start.minute <= cron_time.minute + 30) or 
                (cron_time.hour == pinfo.end.hour and cron_time.minute + 30 <= pinfo.end.minute)
           ):
            return False
        return self.allow(pinfo)
    def allow(self, pinfo):
        raise NotImplementedError('abstract method')
    def how_much_like(self):
        return self.priority

####################################################################################################
####################################################################################################

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
    ]
    def allow(self, pinfo):
        if pinfo.category_1 == 'アニメ／特撮' and pinfo.category_2 == '国内アニメ' and pinfo.start.hour < 6:
            if not re.search(self.deny_pattern, pinfo.title):
                if pinfo.channel != 'CS_331':
                    return True
        return False

class BaseBallFinder(Finder):
    priority = 1
    next_flag = False
    def allow(self, pinfo):
        if self.next_flag:
            self.next_flag = False
            if pinfo.channel != '22' and pinfo.start.hour >= 17:
                return True
            else:
                return False
        if pinfo.channel != '22' and pinfo.start.hour >= 17 and pinfo.category_2 == '野球':
            self.next_flag = True
        return False

class TitleFinder(Finder):
    priority = 100
    allow_list = [
        u'鋼の錬金術師',
        u'ジョジョの奇妙な冒険',
        u'はじめの一歩',
        u'ペルソナ4',
        u'偽物語',
        u'青の祓魔師',
        u'DEATH NOTE',
        u'刀語',
    ]
    def allow(self, pinfo):
        if re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class CreditFinder(Finder):
    priority = 40
    allow_list = [
        u'西尾維新',
        u'浜田雅功',
        u'ダウンタウン',
        u'星野真里',
        u'多部未華子',
        u'宮崎あおい',
        u'堀北真希',
        u'YUI',
        u'ユイ',
        u'蒼井優',
        u'名越康文',
        u'菊川怜',
        u'新垣結衣',
        u'安田美沙子',
        u'西尾維新',
        u'麻枝准',
        u'大塚愛',
        u'レディー・ガガ',
        u'LADY GAGA',
        u'LADY　GAGA',
        u'石原さとみ',
        u'阿部寛',
    ]
    deny_list = [
        u'BSプレマップ',
    ]
    def allow(self, pinfo):
        if not re.search(self.deny_pattern, pinfo.title) and re.search(self.allow_pattern, pinfo.desc):
            return True
        return False

class SportFinder(Finder):
    priority = 40
    def allow(self, pinfo):
        if pinfo.category_2 == 'サッカー' and int(pinfo.channel) > 100:
            return True
        return False

class NewsFinder(Finder):
    priority = 40
    def allow(self, pinfo):
        if pinfo.title == 'ニュースウオッチ9':
            return True
        return False

class F1Finder(Finder):
    priority = 60
    allow_list = [
        u'F1',
    ]
    def allow(self, pinfo):
        if pinfo.category_2 == 'モータースポーツ' and re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class DarwinFinder(Finder):
    priority = 30
    allow_list = [
        u'ダーウィンが来た',
    ]
    def allow(self, pinfo):
        if pinfo.start.hour == 19 and re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class VarietyFinder(Finder):
    priority = 60
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

class EnglishFinder(Finder):
    priority = 40
    allow_list = [
        u'英語',
    ]
    deny_list = [
        u'リトル・チャロ',
        u'高校講座',
        u'トラッドジャパン',
    ]
    def allow(self, pinfo):
        if pinfo.start.hour < 18:
            return False
        if re.search(self.deny_pattern, pinfo.title):
            return False
        if re.search(self.allow_pattern, pinfo.title):
            return True
        if re.search(self.allow_pattern, pinfo.desc):
            return True
        return False


class RandomGenerator:
    def getRandomChannel():
        return random.choice(('BS_200','BS_193','CS_227','CS_240'))
    def getRandomHour():
        return random.choice((20,21))
    getRandomChannel = staticmethod(getRandomChannel)
    getRandomHour = staticmethod(getRandomHour)

class RandomFinder(Finder):
    priority = 1
    random_channel = RandomGenerator.getRandomChannel()
    random_hour = RandomGenerator.getRandomHour()
    rectime = 29 * 60
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
####################################################################################################

class TestTimeFinder(Finder):
    priority = 50
    def allow(self, pinfo):
        if (pinfo.epoch_start - pinfo.epoch_now) < (60 * 60):
            return True
        return False

class TestAllFinder(Finder):
    priority = 1
    def allow(self, pinfo):
        return True
class TestChannelFinder(Finder):
    priority = 1
    def allow(self, pinfo):
        if pinfo.channel == '13' or pinfo.channel == '14' or pinfo.channel == '15':
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