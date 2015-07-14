#!/bin/bash

db_file=/home/mc/xdg-user-dirs/media/bin/rrd/gpu.rrd

sudo intel_gpu_top -s 100 -o - |
awk -v db_file=$db_file '
BEGIN {
    count = 0
    render = 0
    bitstream = 0
    blitter = 0
    cycle = 60 * 5
}

{
    if (2 <= FNR) {
        count++
        render += $2
        bitstream += $6
        blitter += $8

        if (cycle <= count) {
            ave_render = render / cycle
            ave_bitstream = bitstream / cycle
            ave_blitter = blitter / cycle

#             printf(" render=%d%\n bitstream=%d%\n blitter=%d%\n", ave_render, ave_bitstream, ave_blitter)
#             print sprintf("rrdtool update %s N:%d:%d:%d", db_file, ave_render, ave_bitstream, ave_blitter)
            system(sprintf("rrdtool update %s N:%d:%d:%d", db_file, ave_render, ave_bitstream, ave_blitter))

            render = 0
            bitstream = 0
            blitter = 0
            count = 0
        }
    }
}'


# time  render% ops     bitstr% ops     bitstr% ops     blitte% ops     vert f  prim f  VS inv  GS inv  GS pri  CL inv  CL pri  PS inv  PS dep
# 1.01      0     0       -1      -1        0     0         0     0       0       0       0       0       0       0       0       0       0
# 2.01      0     0       -1      -1        0     0         0     0       0       0       0       0       0       0       0       0       0
# 3.02      0     0       -1      -1        0     0         0     0       0       0       0       0       0       0       0       0       0
# 4.03      0     0       -1      -1        0     0         0     0       0       0       0       0       0       0       0       0       0
# 5.03      0     0       -1      -1        0     0         0     0       0       0       0       0       0       0       0       0       0
# 6.04      0     0       -1      -1        0     0         0     0       0       0       0       0       0       0       0       0       0
# 7.05      0     0       -1      -1        0     0         0     0       0       0       0       0       0       0       0       0       0
# 8.05      5     20      -1      -1        2     1         0     0       0       0       0       0       0       0       0       0       0
# 9.06     33     122     -1      -1        6     4         0     0       0       0       0       0       0       0       0       0       0
# 10.07    47     194     -1      -1        7     6         0     0       0       0       0       0       0       0       0       0       0
# 11.07    38     147     -1      -1        4     4         0     0       0       0       0       0       0       0       0       0       0
# 12.08    36     140     -1      -1        4     3         0     0       0       0       0       0       0       0       0       0       0
# 13.09    40     146     -1      -1        6     4         0     0       0       0       0       0       0       0       0       0       0
# 14.09    41     148     -1      -1        2     1         0     0       0       0       0       0       0       0       0       0       0
# 15.10    40     143     -1      -1        4     3         0     0       0       0       0       0       0       0       0       0       0
# 16.11    38     152     -1      -1        7     6         0     0       0       0       0       0       0       0       0       0       0
# 17.11    43     160     -1      -1        6     5         0     0       0       0       0       0       0       0       0       0       0
# 18.12    41     151     -1      -1        4     4         0     0       0       0       0       0       0       0       0       0       0
# 19.13    45     165     -1      -1        2     1         0     0       0       0       0       0       0       0       0       0       0
# 20.13    31     130     -1      -1        6     4         0     0       0       0       0       0       0       0       0       0       0
# 21.14    41     158     -1      -1        7     6         0     0       0       0       0       0       0       0       0       0       0
# 22.15    35     141     -1      -1        5     5         0     0       0       0       0       0       0       0       0       0       0
# 23.15    43     158     -1      -1        6     7         0     0       0       0       0       0       0       0       0       0       0
# 24.16    37     145     -1      -1        4     4         0     0       0       0       0       0       0       0       0       0       0
# 25.17    38     152     -1      -1        6     4         0     0       0       0       0       0       0       0       0       0       0
# 26.17    35     131     -1      -1        7     5         0     0       0       0       0       0       0       0       0       0       0
# 27.18    44     162     -1      -1        5     5         0     0       0       0       0       0       0       0       0       0       0
# 28.19    45     154     -1      -1        6     5         0     0       0       0       0       0       0       0       0       0       0
# 29.19    44     155     -1      -1        7     6         0     0       0       0       0       0       0       0       0       0       0
# 30.20     9     34      -1      -1        1     0         0     0       0       0       0       0       0       0       0       0       0
# 31.21     0     0       -1      -1        0     0         0     0       0       0       0       0       0       0       0       0       0
# 32.21     0     0       -1      -1        0     0         0     0       0       0       0       0       0       0       0       0       0
