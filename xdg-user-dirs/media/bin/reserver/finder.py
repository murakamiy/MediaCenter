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
        if len(pinfo.category_list) == 0:
            return False
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
                date(2014, 7, 21),
                date(2014, 7, 22),
                date(2014, 7, 23),
                )
        if pinfo.channel == "CS_340" and pinfo.start.date() in date_list and re.search("宇宙スペシャル", pinfo.title):
            return True

        if pinfo.channel == "BS_103" and pinfo.start.date() == date(2014, 7, 19) and re.search("クジラ親子に出会う旅", pinfo.title):
            return True

        return False

class TitleFinder(Finder):
    priority = 90
    allow_list = [
        u'NARUTO',
        u'はじめの一歩',
        u'Kanon',
        u'ジョジョの奇妙な冒険',
        u'HERO　',
    ]
    def allow(self, pinfo):
        if re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class MovieFinder(Finder):
    priority = 70
    rectime = 60 * 90
    def allow(self, pinfo):
        if pinfo.channel == 'BS_200' and \
           self.rectime < pinfo.rectime and \
           pinfo.start.hour == 21:
            return True
        return False

class AnimeFinder(Finder):
    priority = 50
    channel_list = ("14", "15", "16", "17", "18", "26")
    def allow(self, pinfo):
        if pinfo.channel in self.channel_list and '国内アニメ' in pinfo.category_list and \
           (pinfo.start.hour >= 23 or pinfo.start.hour <= 4):
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
    def allow(self, pinfo):
        if 'モータースポーツ' in pinfo.category_list:
            if re.search('F1', pinfo.title) and re.search('決勝', pinfo.title):
                return True
            if re.search('WRC', pinfo.title):
                return True
        return False

class CarInfomationFinder(Finder):
    priority = 40
    allow_list = [
        u'カーグラフィックTV',
        u'トップ・ギア　USA',
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
        u'アリアナ・グランデ',
        u'テイラー・スウィフト',
        u'西野カナ',
    ]
    deny_list = [
        u'BSプレマップ',
    ]
    def allow(self, pinfo):
        if not re.search(self.deny_pattern, pinfo.title) and re.search(self.allow_pattern, pinfo.desc):
            return True
        return False

class RandomFinder(Finder):
    def allow(self, pinfo):
        if pinfo.start.hour == self.cron_hour or self.next_cron < pinfo.end:
            return None
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
