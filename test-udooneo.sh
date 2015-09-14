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
VALUEADDR[0]='178'   # j4
VALUEADDR[1]='106'
VALUEADDR[2]='179'
VALUEADDR[3]='107'
VALUEADDR[4]='104'
VALUEADDR[5]='180'
VALUEADDR[6]='143'
VALUEADDR[7]='181'
VALUEADDR[8]='142'
VALUEADDR[9]='172'
VALUEADDR[10]='141'
VALUEADDR[11]='173'
VALUEADDR[12]='140'
VALUEADDR[13]='182'
VALUEADDR[14]='149'
VALUEADDR[15]='124'

VALUEADDR[16]='105'  # j6
VALUEADDR[17]='25'
VALUEADDR[18]='148'
VALUEADDR[19]='23'
VALUEADDR[20]='146'
VALUEADDR[21]='14'
VALUEADDR[22]='147'
VALUEADDR[23]='15'
VALUEADDR[24]='100'
VALUEADDR[25]='16'
VALUEADDR[26]='102'
VALUEADDR[27]='17'
VALUEADDR[28]='18'
VALUEADDR[29]='19'
VALUEADDR[30]='3'
VALUEADDR[31]='20'
VALUEADDR[32]='2'
VALUEADDR[33]='21'

VALUEADDR[34]='125'
VALUEADDR[35]='126'
VALUEADDR[36]='177'
VALUEADDR[37]='145'
VALUEADDR[38]='176'
VALUEADDR[39]='150'
VALUEADDR[40]='175'
VALUEADDR[41]='121'
VALUEADDR[42]='174'
VALUEADDR[43]='120'
#VALUEADDR[44]='202'
#VALUEADDR[45]='203'

VALUEADDR[44]='119'  # j7
VALUEADDR[45]='124'
VALUEADDR[46]='127'
VALUEADDR[47]='116'
VALUEADDR[48]='7'
VALUEADDR[49]='6'
#VALUEADDR[50]='5'  # uart
#VALUEADDR[51]='4'



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
if 	[ ! -f /sys/class/gpio/gpio109/direction ] || 
	[ ! -f /sys/class/gpio/gpio96/direction ] 
then
	log "export Recognition GPIOs..."
	echo 109 > /sys/class/gpio/export # R184
	echo 96 > /sys/class/gpio/export  # R185
	echo in > /sys/class/gpio/gpio109/direction # R184
	echo in > /sys/class/gpio/gpio96/direction  # R185
else 
	log "Recognition GPIOs already exported"
fi

if 	[ ! -f /sys/class/gpio/gpio178/direction ] || 
	[ ! -f /sys/class/gpio/gpio179/direction ] || 
	[ ! -f /sys/class/gpio/gpio180/direction ]
then
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
  iw $DEV_WIFI scan > /dev/null    || log "Wifi not found anything, error $?" $?
  #iw $DEV_WIFI connect  || log "Wifi not connecting, error $?" $?
  #dhclient $DEV_WIFI    || log "Wifi not giving ip address, dhcp fail, error $?" $? 
  
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
	for((i=0; i<50; i+=2))
	{
		echo in > /sys/class/gpio/gpio${VALUEADDR[$i]}/direction
		echo 1 > /sys/class/gpio/gpio${VALUEADDR[$(($i+1))]}/value
		sleep 0.1
		VALUE=$(cat /sys/class/gpio/gpio${VALUEADDR[$i]}/value)
		echo $VALUE
		if [ $VALUE  -eq  1 ]; then
			HIGH=0
		else
			HIGH=-1
		fi
		sleep 0.1
		echo 0 > /sys/class/gpio/gpio${VALUEADDR[$(($i+1))]}/value
		sleep 0.1
		VALUE=$(cat /sys/class/gpio/gpio${VALUEADDR[$i]}/value)
		echo $VALUE
		if [ $VALUE  -eq  0 ]; then
			LOW=0
		else
			LOW=-1
		fi

		if [ $HIGH -eq 0 -a $LOW -eq 0 ]; then
			log "pin $i $(($i+1)) OK"
		else
			log "pin $i $(($i+1)) ERROR" #1
		fi
	}
}

function test_motion_sensor()
{
	# FXOS8700CQ
	i2cset -f -y 3 0x1e 0x2a 1 || log "FXOS8700CQ Acc/Mag, error $?" $?
	# FXAS21002CQR1
	i2cset -f -y 3 0x20 0x13 0x16 || log "FXAS21002CQR1 Gyro, error $?" $?
	
	log "FXOS8700CQ/FXAS21002CQR1 (Acc/Mag - Gyro) OK"
}

function test_audiohdmi()
{
	speaker-test -c2 -twav -l1 || log "Audio HDMI error $?" $?
}

gpio_init
board_version_recognition

#tests
TEST_ETH=0
TEST_WIFI=0
TEST_MOT_SENSOR=0
if [[ $BOARD_MODEL = $FULL ]] || [[ $BOARD_MODEL = $BASIC ]]
then 
	(test_ethernet) ; TEST_ETH=$?
fi

if [[ $BOARD_MODEL != $BASIC ]] 
then 
	(test_wifi) ; TEST_WIFI=$?
fi

if [[ $BOARD_MODEL = $FULL ]] || [[ $BOARD_MODEL = $EXTENDED ]]
then
	(test_motion_sensor); TEST_MOT_SENSOR=$?
fi

(test_usb); TEST_USB=$?

(test_gpio); TEST_GPIO=$?

(test_audiohdmi); TEST_AUDIOHDMI=$?

if (( $TEST_ETH + $TEST_WIFI + $TEST_MOT_SENSOR + $TEST_USB + $TEST_AUDIOHDMI ))
then 
	log "UDOO NEO TEST FAILED" 1
else 
	log "UDOO NEO TEST OK" 0
fi
