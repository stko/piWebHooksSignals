#!/bin/bash
/bin/nc  -l 3000 | /usr/bin/python3 /home/pi/piWebHooksSignals/scripts/piWebHooksMaster.py /etc/piWebHooksSignals/leds.cfg
echo "master ended" >> /tmp/pilog.txt
echo "master ended"
/sbin/poweroff
