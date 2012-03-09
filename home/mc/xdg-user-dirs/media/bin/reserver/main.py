import reserve
import finder
import os

finders_list = []
finders_list.append(finder.AnimeFinder())
finders_list.append(finder.TitleFinder())
finders_list.append(finder.F1Finder())
# finders_list.append(finder.DarwinFinder())
finders_list.append(finder.VarietyFinder())
# finders_list.append(finder.EnglishFinder())
finders_list.append(finder.CreditFinder())
# finders_list.append(finder.SportFinder())
finders_list.append(finder.NewsFinder())


cheif = finder.FindresCheif(finders_list)
r = reserve.ReserveMaker(cheif)
# degital
r.reserve('[0-9]*.xml')

# bs cs
c = (
"151", "152", "153", "161", "162", "163", "171", "172", "173", "211", "222",
"238", "231", "232", "233", "141", "142", "143", "181", "182", "183", "101",
"102", "103", "104")

r.set_include_channel(c)
r.reserve('bs.xml')
