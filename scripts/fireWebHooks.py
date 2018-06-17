from __future__ import print_function
import sys
import requests
import json
import time

def eprint(*args, **kwargs):
	print(*args, file=sys.stderr, **kwargs)

def flushprint(*args, **kwargs):
	print(*args, file=sys.stdout, **kwargs)
	sys.stdout.flush()

with open(sys.argv[1]) as f:
	data = json.load(f)
msgID=0 # read GPIOs here later to select different msgs.
flushprint("ON")
time.sleep( 3 )
try:
	myCfg=data[msgID]
	flushprint("BYELLOW")
	try:
		for hook in myCfg:
			url=hook["url"]
			payload=hook["payload"]
			try:
				requests.post(url, data=payload)
				flushprint("GREEN")
			except:
				flushprint("RED")
				eprint("error sending request")
	except:
		flushprint("RED")
		eprint("format error in config array!")
except:
	flushprint("RED")
	eprint("id {0} not found in config array".format(msgID))
time.sleep( 5 )
flushprint("EXIT")

