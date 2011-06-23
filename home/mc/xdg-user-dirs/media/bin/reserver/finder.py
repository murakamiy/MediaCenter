# -*- coding: utf-8 -*-
from constant import *
import re
import random

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
    priority = PRIORITY_MIDDLE
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
        return False
    def how_much_like(self):
        return self.priority

####################################################################################################
####################################################################################################

class AnimeFinder(Finder):
    deny_list = [
        u'アスタロッテのおもちゃ',
        u'オー！マイキー',
        u'蒼天航路',
        u'タイムボカン',
    ]
    def like(self, pinfo):
        if pinfo.category_en == 'anime' and pinfo.start.hour < 6:
            if not re.search(self.deny_pattern, pinfo.title):
                return True
        return False

class TitleFinder(Finder):
    priority = PRIORITY_HIGH
    allow_list = [
        u'鋼の錬金術師',
        u'刀語',
        u'ドラゴンボール',
        u'ＮＡＲＵＴＯ',
        u'はじめの一歩',
    ]
    def like(self, pinfo):
        if re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class CreditFinder(Finder):
    priority = 40
    allow_list = [
        u'浜田雅功',
        u'ダウンタウン',
        u'星野真里',
        u'多部未華子',
        u'今井りか',
        u'戸田恵梨香',
        u'宮崎あおい',
        u'堀北真希',
        u'長澤まさみ',
        u'YUI',
        u'ＹＵＩ',
        u'蒼井優',
        u'名越康文',
        u'上野樹里',
        u'前田敦子',
        u'菊川怜',
        u'新垣結衣',
        u'安田美沙子',
    ]
    def like(self, pinfo):
        for c in pinfo.credits:
            if re.search(self.allow_pattern, c):
                return True
        return False

class F1Finder(Finder):
    priority = 60
    allow_list = [
        u'Ｆ１',
    ]
    def like(self, pinfo):
        if pinfo.category_en == 'sports' and re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class DarwinFinder(Finder):
    priority = 30
    allow_list = [
        u'ダーウィンが来た',
    ]
    def like(self, pinfo):
        if pinfo.start.hour == 19 and re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class VarietyFinder(Finder):
    priority = 60
    allow_list = [
        u'リンカーン',
        u'ダウンタウンのガキの使いやあらへんで',
        u'とんねるずのみなさんのおかげでした',
        u'さんまのスーパーからくりＴＶ',
    ]
    def like(self, pinfo):
        if pinfo.category_en == 'variety':
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
    def like(self, pinfo):
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
        return random.choice(('14','15','16','17','18'))
    def getRandomHour():
        return random.choice((20,21))
    getRandomChannel = staticmethod(getRandomChannel)
    getRandomHour = staticmethod(getRandomHour)

class RandomFinder(Finder):
    priority = PRIORITY_LOW
    random_channel = RandomGenerator.getRandomChannel()
    random_hour = RandomGenerator.getRandomHour()
    rectime = 29 * 60
    reserved = False
    def like(self, pinfo):
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
    priority = PRIORITY_MIDDLE
    def like(self, pinfo):
        if (pinfo.epoch_start - pinfo.epoch_now) < (60 * 60):
            return True
        return False

class TestAllFinder(Finder):
    priority = PRIORITY_LOW
    def like(self, pinfo):
        return True
class TestChannelFinder(Finder):
    priority = PRIORITY_LOW
    def like(self, pinfo):
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
# channel      =  self.get_text(el.get('channel'))
# title        =  self.get_text(el.find('title').text)
# desc         =  self.get_text(el.find('desc').text)
# category_en  =  self.get_text(c.text)
# category_jp  =  self.get_text(c.text)
# priority     = found_by.how_much_like()
# found_by     = found_by.__class__.__name__
# rectime      = self.epoch_end - self.epoch_start - 10
# credits      = self.credits = [] for e in el.find('credits'): for ee in e.getchildren(): self.credits.append(ee.text)
