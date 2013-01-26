BEGIN {
    FS = ":"
}

# BS朝日2:DTV_DELIVERY_SYSTEM=9|DTV_FREQUENCY=1049480|DTV_ISDBS_TS_ID=0x4010:152
# name BS朝日2
# info DTV_DELIVERY_SYSTEM=9|DTV_FREQUENCY=1049480|DTV_ISDBS_TS_ID=0x4010
# id   152

# NHKEテレ1大阪:DTV_DELIVERY_SYSTEM=8|DTV_FREQUENCY=473142857:2056

# 	{   1, "NHK東京 総合",    557142857 },
# 	{   1, "NHK BS-1",          1318000, 0x40f1 },

{
    name = $1
    info = $2
    number = $3

    split(info, array, "|")
    freq = array[2]
    ts_id = array[3]
    split(freq, array, "=")
    freq = array[2]
    split(ts_id, array, "=") 
    ts_id = array[2]

    if (ts_id == "") {
        printf("%s\t%s\t%s\n", NR, name, freq)
        printf("{ %s, \"%s\", %s },\n", NR, name, freq)
    }
    else {
        printf("%s\t%s\t%s\t%s\n", number, name, freq, ts_id)
        printf("{ %s, \"%s\", %s, %s },\n", number, name, freq, ts_id)
    }
}
