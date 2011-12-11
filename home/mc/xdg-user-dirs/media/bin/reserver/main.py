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

# bs cs
c = ("151", "152", "153", "161", "162", "163", "191", "171", "172", "173",
"192", "193", "201", "202", "236", "211", "200", "222", "238", "241",
"231", "232", "233", "141", "142", "143", "181", "182", "183", "101",
"102", "103", "104", "291", "292", "298", "294", "295", "296", "297",
"234", "242", "243", "7239", "7306", "7256", "7294", "7312", "7322", "7331",
"7334", "7221", "7222", "7223", "7224", "7292", "7310", "7311", "7343", "755",
"7335", "7228", "7800", "7801", "7802", "7260", "7303", "7323", "7324", "7352",
"7353", "7354", "7253", "7254", "7255", "7290", "7305", "7333", "7342", "7803",
"7240", "7262", "7314", "7307", "7308", "7340", "7341", "7160", "7161", "7185",
"7293", "7301", "7304", "7325", "7351", "7257", "7300", "7315", "7321", "7350",
"7362")

r.set_include_channel(c)
r.reserve('bs.xml', 'cs_[0-9]*.xml')
