#!/bin/bash
/usr/bin/python3 /home/pi/piWebHooksSignals/scripts/fireWebHooks.py /etc/piWebHooksSignals/webhooks.cfg | /bin/nc localhost 3000