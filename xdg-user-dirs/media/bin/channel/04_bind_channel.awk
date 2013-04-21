{
    if (log_file_name == FILENAME) {
        for (i = 2; i <= NF; i++) {
            if ($i in sid_array) {
                sid_array[$i] = sid_array[$i]"\t"$1
            }
            else {
                sid_array[$i] = $1
            }
        }
    }
    else if (channel_file_name == FILENAME){
        if ($2 in sid_array) {
            printf("%s\t%s\n", $0, sid_array[$2])
        }
        else {
            print "not found : "$0
        }
    }
}
