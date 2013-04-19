BEGIN {
    block_start = 0
    block_end = 0
    channel_line = 0
    sid_line = 0
    sid_array_size = 0
}

/^#---->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>#$/ {
    block_start = 1
    block_end = 0
}

/^#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<----#$/ {
    block_start = 0
    block_end = 1
}

/^# CHANNEL=/ {
    channel_line = 1
}

! /^# CHANNEL=/ {
    channel_line = 0
}

/^Available sid / {
    sid_line = 1
}

! /^Available sid / {
    sid_line = 0
}

{

    if (block_start == 1) {
        if (channel_line == 1) {
            split($0, array, "=")
            channel = array[2]
        }
        if (sid_line == 1) {
            split($0, array, " = ")
            sid_array_size = split(array[2], sid_array)
        }
    }
    if (block_end == 1) {
        if (sid_array_size != 0) {
           printf("%s", channel)
           for (sid in sid_array) {
               printf("\t%s", sid_array[sid])
           }
           printf("\n")
        }
        sid_array_size = 0
    }

}
