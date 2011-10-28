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

cheif = finder.FindresCheif(finders_list)
r = reserve.ReserveMaker(cheif)
# degital
r.reserve('[0-9]*.xml')
# bs
c = ("101", "103", "141", "151", "161", "171", "181", "211")
r.set_include_channel(c)
r.reserve('bs.xml')
