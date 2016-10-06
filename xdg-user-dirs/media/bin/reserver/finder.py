# -*- coding: utf-8 -*-
import re
import random
from datetime import date
from datetime import datetime

FILE_RELEASE = 'release'
FILE_KEEP = 'keep'

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
            pinfo.original_file = found_by.original_file
            pinfo.encode_width = found_by.encode_width
            pinfo.encode_height = found_by.encode_height
            pinfo.encode_bitrate = found_by.encode_bitrate
            pinfo.do_encode = found_by.do_encode
            return pinfo

class Finder:
    priority = 50
    rectime_max = 60 * 60 * 6
    rectime_min = 60 * 20
    allow_list = None
    deny_list = None
    allow_pattern = None
    deny_pattern = None
    original_file = FILE_KEEP
    encode_width = 640
    encode_height = 360
    encode_bitrate = '500k'
    do_encode = True
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
        return False

class NarutoFinder(Finder):
    priority = 90
    do_encode = False
    def allow(self, pinfo):
        if re.search('NARUTO', pinfo.title):
            return True
        return False

class TitleFinder(Finder):
    priority = 90
    allow_list = [
        u'__________',
        u'アルスラーン戦記',
        u'ジョジョの奇妙',
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
           20 <= pinfo.start.hour and pinfo.start.hour <= 21:
            return True
        return False

class AnimeFinder(Finder):
    priority = 50
    do_encode = False
    channel_list = ("14", "15", "16", "17", "18", "26", "BS_211")
    def allow(self, pinfo):
        if pinfo.channel in self.channel_list and '国内アニメ' in pinfo.category_list and \
           (pinfo.start.hour >= 23 or pinfo.start.hour <= 4):
            return True
        return False

class BoxingFinder(Finder):
    original_file = FILE_RELEASE
    priority = 30
    allow_list = [
        u'エキサイトマッチ',
    ]
    def allow(self, pinfo):
        if re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class MoterSportsFinder(Finder):
    original_file = FILE_RELEASE
    priority = 30
    def allow(self, pinfo):
        if 'モータースポーツ' in pinfo.category_list:
            if re.search('F1', pinfo.title) and re.search('決勝', pinfo.title):
                return True
            if re.search('WRC', pinfo.title):
                return True
            if re.search('FIAフォーミュラE選手権', pinfo.title):
                return True
        return False

class CarInfomationFinder(Finder):
    original_file = FILE_RELEASE
    priority = 30
    def allow(self, pinfo):
        if re.search('カーグラフィックTV', pinfo.title) and pinfo.channel != 'CS_299':
            return True
        return False

class CultureFinder(Finder):
    original_file = FILE_RELEASE
    priority = 30
    allow_list = [
        u'スーパープレゼンテーション',
        u'THE NAKED',
    ]
    def allow(self, pinfo):
        if re.search(self.allow_pattern, pinfo.title):
            return True
        return False

class NatureFinder(Finder):
    original_file = FILE_KEEP
    priority = 40
    allow_list = [
        u'プラネットアース',
        u'BBC　EARTH',
    ]
    def allow(self, pinfo):
        if not '自然・動物・環境' in pinfo.category_list:
            return False
        if re.search(self.allow_pattern, pinfo.title):
            return True
        if pinfo.channel == '16' and re.search('世界遺産', pinfo.title):
            return True
        return False

class MusicFinder(Finder):
    original_file = FILE_RELEASE
    priority = 30
    allow_list = [
        u'ベストヒットUSA',
    ]
    today = datetime.now().weekday
    def allow(self, pinfo):
        if re.search(self.allow_pattern, pinfo.title):
            return True
        if self.today == 1 and re.search(u'(洋楽|邦楽)トップヒッツ', pinfo.title):
            return True
        return False

class CreditFinder(Finder):
    original_file = FILE_RELEASE
    priority = 30
    allow_list = [
        u'アリアナ・グランデ',
        u'テイラー・スウィフト',
    ]
    deny_list = [
        u'BSプレマップ',
    ]
    def allow(self, pinfo):
        if not re.search(self.deny_pattern, pinfo.title) and re.search(self.allow_pattern, pinfo.desc):
            return True
        return False

class RandomFinder(Finder):
    original_file = FILE_RELEASE
    def allow(self, pinfo):
        if pinfo.start.hour == self.cron_hour or self.next_cron < pinfo.end:
            return None
        if re.search('放送休止', pinfo.title) or re.search('文字放送', pinfo.title) or re.search('調整用カラーバー', pinfo.title):
            return None
        if 'ショッピング・通販' in pinfo.category_list:
            return None

        pinfo.found_by = self.__class__.__name__
        pinfo.priority = random.choice((1,2,3,4,5)) + 10.0 * pinfo.rectime / self.rectime_max
        pinfo.original_file = self.original_file
        pinfo.encode_width = self.encode_width
        pinfo.encode_height = self.encode_height
        pinfo.encode_bitrate = self.encode_bitrate
        pinfo.do_encode = self.do_encode

        if pinfo.channel not in ('CS_340', 'CS_341', 'CS_343'):
            pinfo.priority -= 20

        if not '自然・動物・環境' in pinfo.category_list:
            pinfo.priority -= 20

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
