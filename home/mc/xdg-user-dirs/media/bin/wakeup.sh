#!/bin/bash
log=/home/mc/log

echo -n > $log
echo "gnome-session-quit --logout" >> $log
gnome-session-quit --logout
echo killall -s HUP lcdclock >> $log
killall -s HUP lcdclock
echo sleep 10 >> $log
sleep 10

wakeup=$(awk 'BEGIN { print systime() + 300 }')
echo sudo lcdprint -q -w $wakeup >> $log
sudo lcdprint -q -w $wakeup
echo "sudo wakeuptool -w -t $wakeup" >> $log
sudo wakeuptool -w -t $wakeup
