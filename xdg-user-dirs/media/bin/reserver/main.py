import sys
import reserve
import finder

finders_list = []
finders_list.append(finder.AnimeFinder())
finders_list.append(finder.TitleFinder())
finders_list.append(finder.F1Finder())
# finders_list.append(finder.DarwinFinder())
# finders_list.append(finder.VarietyFinder())
# finders_list.append(finder.EnglishFinder())
finders_list.append(finder.CreditFinder())
# finders_list.append(finder.SportFinder())
# finders_list.append(finder.NewsFinder())
finders_list.append(finder.RandomFinder())
finders_list.append(finder.BoxingFinder())
finders_list.append(finder.CreditFinderHigh())

cheif = finder.FindresCheif(finders_list)
r = reserve.ReserveMaker(cheif)

xml_globs = sys.argv[1:]
for xml_glob in xml_globs:
    r.reserve(xml_glob)
