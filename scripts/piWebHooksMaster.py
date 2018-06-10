from threading import Thread
from queue import Queue, Empty
import sys
import json
from gpiozero import LED

from time import sleep

from pprint import pprint

class NonBlockingStreamReader:

	def __init__(self, stream):
		'''
		stream: the stream to read from.
				Usually a process' stdout or stderr.
		'''

		self._s = stream
		self._q = Queue()

		def _populateQueue(stream, queue):
			'''
			Collect lines from 'stream' and put them in 'quque'.
			'''

			while True:
				line = stream.readline()
				if line:
					queue.put(line)
				else:
					raise UnexpectedEndOfStream

		self._t = Thread(target = _populateQueue,
				args = (self._s, self._q))
		self._t.daemon = True
		self._t.start() #start collecting lines from the stream

	def readline(self, timeout = None):
		try:
			return self._q.get(block = timeout is not None,
					timeout = timeout)
		except Empty:
			return None

class UnexpectedEndOfStream(Exception): pass

def updateLEDStates():
	global ledStates
	for idx, val in ledStates.items():
		if val["actstate"]>1:
			if val["actstate"]==2: # time to change the state..
				val["led"].toggle()
				val["actstate"]=val["state"]
			else:
				val["actstate"]-=1


def evalCmd(cmd):
	global data
	global ledStates
	cmd=cmd.upper().strip()
	try:
		for idx, val in enumerate(data["commands"][cmd]):
			if val==-1:
				continue
			ledStates[idx]["state"]=val
			ledStates[idx]["actstate"]=val
			if val>0:
				ledStates[idx]["led"].on()
			else:
				ledStates[idx]["led"].off()
	except: # command does not exist
		print ('Inknown command',cmd)
	
# wrap sys.stdin with a NonBlockingStreamReader object:
nbsr = NonBlockingStreamReader(sys.stdin)
# readConfig
with open(sys.argv[1]) as f:
    data = json.load(f)
pprint(data)
ledStates={}
for idx, val in enumerate(data["config"]):
  ledStates[idx]={}
  ledStates[idx]["led"]=LED(val)
  ledStates[idx]["state"]=0
  ledStates[idx]["actstate"]=0

evalCmd("INIT")
# get the cmd
while True:
	cmd = nbsr.readline(0.5) # 0.1 secs to let the shell cmd the result
	if cmd:
		print ("--",cmd)
		evalCmd(cmd)
	updateLEDStates()
