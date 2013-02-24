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
# finders_list.append(finder.NewsFinder())


cheif = finder.FindresCheif(finders_list)
r = reserve.ReserveMaker(cheif)
# degital
r.reserve('[0-9]*.xml')

# bs
r.reserve('bs.xml')

# cs
r.reserve('cs_[0-9]*.xml')
