#!/bin/bash
/bin/echo "fire 1" >> /tmp/firelog.txt
#ifup ppp0
wvdial gsmstick > /tmp/wvdial.log  2>&1 &
/bin/sleep 3
/bin/echo "fire 2" >> /tmp/firelog.txt
/bin/ping -c 2 google.de
/usr/bin/python3 /home/pi/piWebHooksSignals/scripts/fireWebHooks.py /etc/piWebHooksSignals/webhooks.cfg | /bin/nc localhost 3000
/bin/echo "fire 3" >> /tmp/firelog.txt
