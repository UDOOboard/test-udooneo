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
	echo "export GPIOs..."
  echo 109 > /sys/class/gpio/export # R184
	echo 96 > /sys/class/gpio/export  # R185
	echo in > /sys/class/gpio/gpio109/direction # R184
	echo in > /sys/class/gpio/gpio96/direction  # R185
else 
	echo "GPIOs already exported"
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

gpio_init
board_version_recognition

#tests

(test_ethernet) ; TEST_ETH=$?

(test_wifi) ; TEST_WIFI=$?

(test_usb); TEST_USB=$?

