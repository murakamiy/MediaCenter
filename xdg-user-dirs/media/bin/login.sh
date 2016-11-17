#!/bin/bash
source $(dirname $0)/00.conf

battery_level=$(upower -i /org/freedesktop/UPower/devices/keyboard_sony_controller_battery_04o98of3o72oddo2c | grep percentage | awk '{ printf("%d", $2) }')
if [ "$battery_level" -ge 0 -a "$battery_level" -le 100 ];then
    sleep_time=$((60 * 30 * ($battery_level / 25)))
else
    sleep_time=$((60 * 30))
fi

zenity --info --no-wrap --timeout=30 --display=:0.0 --text="<span font_desc='40'>battry level $battery_level%</span>" &

while true;do
    sleep $sleep_time
    echo disconnect | sudo /usr/bin/bluetoothctl
done &
