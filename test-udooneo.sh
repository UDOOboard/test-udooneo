#!/bin/bash
################################################################################

# UDOO Neo Testing Script

# by Ekirei & Ek5

################################################################################

MOUNTED=0
NOTMOUNTED=1

FULL=0
EXTENDED=1
BASIC=2
BASICKS=3

DEV_ETH=eth0
DEV_WIFI=wlan0

# put all gpio in an array with indexes referring the arduino pinout
VALUEADDR[0]='170'
VALUEADDR[1]='179'
VALUEADDR[2]='104'
VALUEADDR[3]='143'
VALUEADDR[4]='142'
VALUEADDR[5]='141'
VALUEADDR[6]='140'
VALUEADDR[7]='149'

VALUEADDR[8]='105'
VALUEADDR[9]='148'
VALUEADDR[10]='146'
VALUEADDR[11]='147'
VALUEADDR[12]='100'
VALUEADDR[13]='102'
VALUEADDR[14]='3'
VALUEADDR[15]='2'

VALUEADDR[16]='106'
VALUEADDR[17]='107'
VALUEADDR[18]='180'
VALUEADDR[19]='181'
VALUEADDR[20]='172'
VALUEADDR[21]='173'
VALUEADDR[22]='182'
VALUEADDR[23]='24'

VALUEADDR[24]='25'
VALUEADDR[25]='22'
VALUEADDR[26]='14'
VALUEADDR[27]='15'
VALUEADDR[28]='16'
VALUEADDR[29]='17'
VALUEADDR[30]='18'
VALUEADDR[31]='19'
VALUEADDR[32]='20'
VALUEADDR[33]='21'

VALUEADDR[34]='120'
VALUEADDR[35]='121'
VALUEADDR[36]='150'
VALUEADDR[37]='145'
VALUEADDR[38]='125'
VALUEADDR[39]='126'

VALUEADDR[40]='174'
VALUEADDR[41]='175'
VALUEADDR[42]='176'
VALUEADDR[43]='177'
VALUEADDR[44]='202'
VALUEADDR[45]='203'

VALUEADDR[46]='4'
VALUEADDR[47]='5'
VALUEADDR[48]='6'
VALUEADDR[49]='7'
VALUEADDR[50]='116'
VALUEADDR[51]='127'
VALUEADDR[52]='124'
VALUEADDR[53]='119'



# check the if root?
userid=`id -u`
if [ $userid -ne "0" ]; then
	echo "You're not root?"
	exit
fi

usage() {
 echo "Usage: $0 
 " 
}
  
error() {
  #error($E_TEXT,$E_CODE)

  local E_TEXT=$1
  local E_CODE=$2
  
  [[ -z $E_CODE ]] && E_CODE=1
  [[ -z $E_TEXT ]] || echo $E_TEXT >&2
  exit $E_CODE
}

ok() {
  #ok($OK_TEXT)
  local OK_TEXT=$1
  [[ -z $OK_TEXT ]] && OK_TEXT="Success!!"
  [[ -z $OK_TEXT ]] || echo $OK_TEXT 
  exit 0
}

usagee(){
  usage
  error "$1" "$2"
}

log(){
 echo "$1" 
 
 (( $2 )) || return 0
 
 exit $2
}



function gpio_init(){
if [ ! -f /sys/class/gpio/gpio109/direction ] || [ ! -f /sys/class/gpio/gpio96/direction ]; then
	log "export Recognition GPIOs..."
	echo 109 > /sys/class/gpio/export # R184
	echo 96 > /sys/class/gpio/export  # R185
	echo in > /sys/class/gpio/gpio109/direction # R184
	echo in > /sys/class/gpio/gpio96/direction  # R185
else 
	log "Recognition GPIOs already exported"
fi

if [ ! -f /sys/class/gpio/gpio170/direction ] || [ ! -f /sys/class/gpio/gpio179/direction ]; then
	log "export Pinheader GPIOs..."
	for i in ${!VALUEADDR[*]}; do
		echo ${VALUEADDR[$i]} > /sys/class/gpio/export
		echo out > /sys/class/gpio/gpio${VALUEADDR[$i]}/direction
	done
else
	log "Recognition GPIOs already exported"
fi
}

function board_version_recognition()
{
	
	R184=`cat /sys/class/gpio/gpio109/value` # R184
	R185=`cat /sys/class/gpio/gpio96/value`  # R185
	
	echo $R184
	echo $R185
	
	if [ $R184 -eq $NOTMOUNTED ] && [ $R185 -eq $MOUNTED ]; then
		BOARD_MODEL=$FULL
		echo 'UDOO NEO FULL'
	elif [ $R184 -eq $NOTMOUNTED ] && [ $R185 -eq $NOTMOUNTED ]; then
		BOARD_MODEL=$EXTENDED
		echo 'UDOO NEO EXTENDED'
	elif [ $R184 -eq $MOUNTED ] && [ $R185 -eq $MOUNTED ]; then
		BOARD_MODEL=$BASIC
		echo 'UDOO BASIC'
	elif [ $R184 -eq $MOUNTED ] && [ $R185 -eq $NOTMOUNTED ]; then
		BOARD_MODEL=$BASICKS
		echo 'UDOO BASIC KICKSTARTER'
	fi
}

function test_ethernet()
{
  log "TEST Ethernet"
  
  dhclient $DEV_ETH || log "Ethernet not functioning error $?" $? 
  
  log "Ethernet DHCP ok"
}

function test_wifi()
{
  log "TEST Wireless"
  
  ifconfig $DEV_WIFI up || log "Wifi not showing up, error $?" $?
  iw $DEV_WIFI scan     || log "Wifi not found anything, error $?" $?
  iw $DEV_WIFI connect  || log "Wifi not connecting, error $?" $?
  dhclient $DEV_WIFI    || log "Wifi not giving ip address, dhcp fail, error $?" $? 
  
  log "WIFI ok"
}

function test_usb()
{
  log "TEST Usb"
  
  lsusb || log "lsusb failed, error $?" $?
  
  log "USB OK"
}

function test_gpio()
{
for((i=0; i<54; i+=2))
{
	echo in > /sys/class/gpio/gpio${VALUEADDR[$(($i+1))]}/direction
	echo 1 > /sys/class/gpio/gpio${VALUEADDR[$i]}/value
	sleep 0.1
	VALUE=$(cat /sys/class/gpio/gpio${VALUEADDR[$(($i+1))]}/value)
	if [ $VALUE  -eq  1 ]; then
		HIGH=0
	else
		HIGH=-1
	fi
	sleep 0.1
	echo 0 > /sys/class/gpio/gpio${VALUEADDR[$i]}/value
	sleep 0.1
	VALUE=$(cat /sys/class/gpio/gpio${VALUEADDR[$(($i+1))]}/value)
	if [ $VALUE  -eq  0 ]; then
		LOW=0
	else
		LOW=-1
	fi

	if [ $HIGH -eq 0 -a $LOW -eq 0 ]; then
		log "pin $i $(($i+1)) OK"
	else
		log "pin $i $(($i+1)) ERROR"
	fi
}
}

gpio_init
board_version_recognition
test_gpio

#tests

(test_ethernet) ; TEST_ETH=$?

(test_wifi) ; TEST_WIFI=$?

(test_usb); TEST_USB=$?

