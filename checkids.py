import os,sys,time
import hashlib
from subprocess import Popen
from subprocess import PIPE

def runsys(s):
	with Popen(s.split(' '), stdout=PIPE) as proc:
		return proc.stdout.read().decode('utf-8')

################################## SYSTEM AND HARDWARE FUNCTIONS #################################
def isPlatformARM():
	model= os.popen('cat /proc/cpuinfo |grep architecture').read().split('\n')[0]
	if ': 8' in model:
		return True
	else:
		return False

def isPlatformX86():
	if ('x86_64' in os.popen('uname -m').read()):
		return True
	else:
		return False

def isPlatformVM():
	try:
		if str(getConfig('Force NONVM')).upper()=='YES':
			ggb('Forcing to be a NON VM Returning False to isPlatformVM')
			return False
	except:
		pass
	VM=False
	s=os.popen('sudo dmidecode -s system-manufacturer').read()
	for i in ['innotek','QEMU','VirtualBox','Bochs','KVM','Microsoft Corporation','HVM domU']:
		if i in s:
			VM=True
	s2=os.popen('sudo systemd-detect-virt').read()
	if not(s2 == 'none\n'):
		VM=True
	return VM


def isPlatformRP(): #raspberry
	return False # CORRECTION FOR ORANGE PI - IT MUST BEIS PLATFORM ARM


def getMotherBoardSerial():
	return os.popen('sudo cat /sys/class/dmi/id/product_uuid').read().split('\n')[0]  


def getMemorySerials():
	mems=[]
	s=os.popen('sudo lshw -class memory |grep serial:').read().split('\n')[:-1]
	s.sort()
	for i in s:    
		if not 'Unknown' in i:
			mems.append(i.split('serial: ')[1])
	return mems

def getProcessorId():
	return os.popen('sudo dmidecode -t 4 |grep ID').read().split('ID: ')[1].split('\n')[0]

def getRootDev():
	s=os.popen('sudo mount |grep "on / type"').read().split()[0]
	if 'nvme' in s:
		return s.split('/')[-1].split('p')[0]
	if 'da' in s:
		return s.split('/')[-1][:-1]
	else:
		return s.split('/')[-1].split('p')[0]

def getRootDevSerial():
	s=getRootDev()
	return os.popen('sudo lsblk -o NAME,SERIAL,TYPE |grep disk |grep '+s).read().split()[-2]
	

def getAllIfNames():
	ifaces=[]
	s=os.popen('sudo ifconfig -a').read().split('\n\n')[:-1]
	for i in s:
		ifaces.append(i.split(':')[0])
	return ifaces

def getEthIfNames():
	ret=getAllIfNames()
	ifaces=[]
	for i in ret:
		if i[0].lower()=='e':
			ifaces.append(i)
	return ifaces

def getWifiIfNames():
	#try except does not work Very Important Only Subprocess throws exceptions
	return os.popen('sudo ls /sys/class/ieee80211/*/device/net/ 2>/dev/null').read().split('\n')[:-1]

def getEthCardMacId(eth):
	return os.popen('sudo ifconfig '+eth+' |grep ether').read().split()[1]

def getEthCardIds():
	ret=[]
	for i in getEthIfNames():
		ret.append(getEthCardMacId(i))
	for i in getWifiIfNames():
		ret.append(getEthCardMacId(i))
	return ret	


def getMachineId_OPIZ2():
        usbser=runsys('sudo cat /sys/firmware/devicetree/base/soc@03000000/usbc0@0/usb_serial_number')
        wlanser=runsys('sudo cat /sys/class/net/wlan0/address')
        ethser=runsys('sudo cat /sys/class/net/eth0/address')
        return hashlib.sha256((usbser+wlanser+ethser).encode()).hexdigest().upper()

def getMachineId_X86(): # New Version 
	# it is all the same for A10N-8800E  # not querying Cpu id or mb id since they are always same ...
	# Old versions are in git ... You can check them out 
	s=''.join(getMemorySerials()) + getRootDevSerial() +''.join(getEthCardIds())
	return hashlib.sha256(s.encode()).hexdigest().upper()


if (isPlatformARM()):
	getMachineId=getMachineId_OPIZ2

if (isPlatformX86()):
	getMachineId=getMachineId_X86

with Popen(["sudo","sha256sum","/etc/shadow"], stdout=PIPE) as proc: 
        sout=proc.stdout.read().decode('ascii').split('\n')

etcshdw=sout[0].split(' ')[0]

print('longuuid='+getMachineId())
print('etcshadow='+etcshdw)

