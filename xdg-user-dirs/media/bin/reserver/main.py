import sys
import reserve
import finder

finders_list = []
finders_list.append(finder.AnimeFinder())
finders_list.append(finder.TitleFinder())
finders_list.append(finder.F1Finder())
finders_list.append(finder.CreditFinder())
finders_list.append(finder.MovieFinder())
finders_list.append(finder.BoxingFinder())
finders_list.append(finder.CreditFinderHigh())

cheif = finder.FindresCheif(finders_list)
r = reserve.ReserveMaker(cheif)

xml_globs = sys.argv[1:]
r.reserve(xml_globs)
