import sys
import reserve
import finder

finders_list = []
finders_list.append(finder.AnimeFinder())
finders_list.append(finder.TitleFinder())
finders_list.append(finder.MoterSportsFinder())
finders_list.append(finder.CarInfomationFinder())
finders_list.append(finder.CreditFinder())
finders_list.append(finder.MovieFinder())
finders_list.append(finder.BoxingFinder())
finders_list.append(finder.CreditHighFinder())
finders_list.append(finder.MusicFinder())
finders_list.append(finder.CultureFinder())
finders_list.append(finder.VarietyFinder())
finders_list.append(finder.NatureFinder())

cheif = finder.FindresCheif(finders_list)
r = reserve.ReserveMaker(cheif, finder.RandomFinder())
r.set_exclude_channel(("bs_291", "bs_292", "bs_294", "bs_295", "bs_296", "bs_297", "bs_298"))

xml_globs = sys.argv[1:]
r.reserve(xml_globs)
