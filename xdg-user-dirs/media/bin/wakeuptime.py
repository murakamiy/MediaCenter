import sys
import os
import os.path
from time import localtime
from time import mktime
from time import strptime
from time import strftime
from dateutil import rrule
from datetime import datetime

NO_RESERVED_JOB = 0
NO_SHUTDOWN = -1

def ensure_wakeup(now, wake):
    return wake - 60 * 5 if now < (wake - 60 * 15) else NO_SHUTDOWN
def epoch2str(epoch):
    if (epoch == NO_SHUTDOWN):
        return "no shutdown"
    return strftime("%Y/%m/%d %H:%M:%S", localtime(epoch))


LOG_FILE = os.environ["MC_FILE_LOG"]
CRON_TIME = os.environ["MC_CRON_TIME"]
next_job_epoch = int(sys.argv[1])
current_epoch = int(mktime(localtime()))

cron = map(int, CRON_TIME.split(":"))
now = datetime.now()
rule = rrule.rrule(rrule.DAILY,
        dtstart=datetime(now.year, now.month, now.day, cron[0], cron[1], cron[2]))
cron_job_epoch = int(mktime(rule.after(now).timetuple()))

if next_job_epoch == NO_RESERVED_JOB:
    wakeup = ensure_wakeup(current_epoch, cron_job_epoch)
elif next_job_epoch <= current_epoch:
    wakeup = NO_SHUTDOWN
else:
    wakeup = ensure_wakeup(current_epoch, min(next_job_epoch, cron_job_epoch))

# log = open(LOG_FILE, "a")
# print >> log, "%s\n current= %s\n next_job=%s\n cron_job=%s\n wakeup=  %s" % (os.path.basename(sys.argv[0]), epoch2str(current_epoch), epoch2str(next_job_epoch), epoch2str(cron_job_epoch), epoch2str(wakeup))
# log.close()
print wakeup
