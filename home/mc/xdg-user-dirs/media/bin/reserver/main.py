import reserve
import finder
import xmltv
import os

DEBUG_ENABLED = os.environ["MC_DEBUG_ENABLED"] == "true"

xmltv.Credits.merge()

finders_list = []
if DEBUG_ENABLED:
    finders_list.append(finder.RandomFinder())
else:
    finders_list.append(finder.AnimeFinder())
    finders_list.append(finder.TitleFinder())
    finders_list.append(finder.F1Finder())
    finders_list.append(finder.DarwinFinder())
    finders_list.append(finder.VarietyFinder())
    finders_list.append(finder.EnglishFinder())
    finders_list.append(finder.CreditFinder())


cheif = finder.FindresCheif(finders_list)
r = reserve.ReserveMaker(cheif)
r.reserve()
