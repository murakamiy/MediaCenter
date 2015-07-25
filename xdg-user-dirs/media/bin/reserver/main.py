import sys
import re
import reserve
import finder

args = sys.argv[1:]
xml_globs = []
dry_run = False
for a in args:
    if re.search('^DRY_RUN$', a):
        dry_run = True
    else:
        xml_globs.append(a)


finders_list = []
finders_list.append(finder.AnimeFinder())
# finders_list.append(finder.TitleFinder())
finders_list.append(finder.MoterSportsFinder())
finders_list.append(finder.CarInfomationFinder())
# finders_list.append(finder.CreditFinder())
finders_list.append(finder.MovieFinder())
finders_list.append(finder.BoxingFinder())
finders_list.append(finder.MusicFinder())
finders_list.append(finder.CultureFinder())
finders_list.append(finder.NatureFinder())
# finders_list.append(finder.DateTimeFinder())

cheif = finder.FindresCheif(finders_list)
# r = reserve.ReserveMaker(cheif, None, dry_run)
r = reserve.ReserveMaker(cheif, finder.RandomFinder(), dry_run)
r.set_exclude_channel(("BS_234", "BS_291", "BS_292", "BS_294", "BS_295", "BS_296", "BS_297", "BS_298"))
r.reserve(xml_globs)
