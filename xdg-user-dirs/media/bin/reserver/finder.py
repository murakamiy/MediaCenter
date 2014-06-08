# -*- coding: utf-8 -*-
import re
import random
from datetime import date

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
    rectime_max = 60 * 60 * 6
    rectime_min = 60 * 20
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
        if pinfo.rectime > self.rectime_max:
            return False
        if pinfo.rectime < self.rectime_min:
            return False
        return self.allow(pinfo)
    def allow(self, pinfo):
        raise NotImplementedError('abstract method')
    def how_much_like(self):
        return self.priority

####################################################################################################
####################################################################################################

class DateTimeFinder(Finder):
    priority = 100
    def allow(self, pinfo):
        date_list = (
                date(2014, 6, 23),
                date(2014, 6, 24),
                date(2014, 6, 25),
                date(2014, 6, 26),
                date(2014, 6, 27),
                date(2014, 6, 28),
                )
        if pinfo.channel == "CS_342" and pinfo.start.date() in date_list and re.search("知られざる第一次世界大戦", pinfo.title):
            return True

        if pinfo.channel == "CS_240" and pinfo.start.date() == date(2014, 6, 7) and re.search("PARKER", pinfo.title):
            return True

        if pinfo.channel == "BS_193" and pinfo.start.date() == date(2014, 6, 14) and re.search("パシフィック", pinfo.title):
            return True

        if pinfo.channel == "BS_103" and pinfo.start.date() == date(2014, 6, 23) and re.search("マイレージ", pinfo.title):
            return True

        date_list = (
                date(2014, 6, 2),
                date(2014, 6, 3),
                date(2014, 6, 4),
                date(2014, 6, 5),
                )
        if pinfo.channel == "BS_101" and pinfo.start.date() in date_list and re.search("ノルマンディー上陸", pinfo.title):
            return True

        if pinfo.channel == "BS_103" and pinfo.start.date() == date(2014, 6, 23) and re.search("マイレージ", pinfo.title):
            return True

        return False

class TitleFinder(Finder):
    priority = 90
    allow_list = [
        u'NARUTO',
        u'はじめの一歩',
        u'Kanon',
        u'ジョジョの奇妙な冒険',
        u'頭文字D',
        u'花咲舞が黙ってない',
        u'ニセコイ',
        u'ソウルイーターノット',
        u'ログ・ホライズン',
        u'好きっていいなよ',
    ]
    def allow(self, pinfo):
        if re.search(self.allow_pattern, pinfo.title):
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

class AnimeFinder(Finder):
    priority = 50
    deny_list = [
        u'デジタルリマスターHD版',
    ]
    def allow(self, pinfo):
        if pinfo.broadcasting == 'Digital' and '国内アニメ' in pinfo.category_list and \
           (pinfo.start.hour >= 23 or pinfo.start.hour <= 4):
            if not re.search(self.deny_pattern, pinfo.title):
                return True
        return False

class BoxingFinder(Finder):
    priority = 40
    allow_list = [
        u'ボクシング',
        u'エキサイトマッチ',
    ]
    def allow(self, pinfo):
        if re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class MoterSportsFinder(Finder):
    priority = 40
    allow_list = [
        u'F1',
        u'WRC',
    ]
    def allow(self, pinfo):
        if 'モータースポーツ' in pinfo.category_list and re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class CarInfomationFinder(Finder):
    priority = 40
    allow_list = [
        u'カーグラフィックTV',
    ]
    def allow(self, pinfo):
        if re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class CultureFinder(Finder):
    priority = 30
    allow_list = [
        u'スーパープレゼンテーション',
        u'THE世界遺産',
    ]
    def allow(self, pinfo):
        if re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class NatureFinder(Finder):
    priority = 30
    def allow(self, pinfo):
        r = random.choice((1,2,3,4,5))
        if r == 1 and '自然・動物・環境' in pinfo.category_list:
            return True
        return False

class MusicFinder(Finder):
    priority = 30
    allow_list = [
        u'ベストヒットUSA',
    ]
    def allow(self, pinfo):
        if re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class CreditFinder(Finder):
    priority = 30
    allow_list = [
        u'YUI',
    ]
    deny_list = [
        u'BSプレマップ',
    ]
    def allow(self, pinfo):
        if not re.search(self.deny_pattern, pinfo.title) and re.search(self.allow_pattern, pinfo.desc):
            return True
        return False

class VarietyFinder(Finder):
    priority = 30
    allow_list = [
        u'とんねるずのみなさんのおかげでした',
    ]
    def allow(self, pinfo):
        if 'バラエティ' in pinfo.category_list:
            if re.search(self.allow_pattern, pinfo.title):
                return True
            if re.search(self.allow_pattern, pinfo.desc):
                return True
        return False

class RandomFinder(Finder):
    def allow(self, pinfo):
        if pinfo.title == '放送休止' or pinfo.title == '文字放送':
            return None
        if 'ショッピング・通販' in pinfo.category_list:
            return None

        pinfo.found_by = self.__class__.__name__
        pinfo.priority = random.choice((1,2,3,4,5)) + 10.0 * pinfo.rectime / self.rectime_max

        if '映画' in pinfo.category_list:
            pinfo.priority += 5

        if '洋画' in pinfo.category_list:
            pinfo.priority += 10

        return pinfo

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
# category_list = for c in el.findall('category'): self.category_list.append(self.get_text(c.text))
# priority     = found_by.how_much_like()
# found_by     = found_by.__class__.__name__
# rectime      = self.epoch_end - self.epoch_start - 10
# channel      = self.get_text(el.get('channel'))
# broadcasting = 'BS' || 'CS' || 'Digital'
