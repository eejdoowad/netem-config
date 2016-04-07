#!/bin/bash
#
#  tc uses the following units when passed as a parameter.
#  kbps: Kilobytes per second 
#  mbps: Megabytes per second
#  kbit: Kilobits per second
#  mbit: Megabits per second
#  bps: Bytes per second 
#       Amounts of data can be specified in:
#       kb or k: Kilobytes
#       mb or m: Megabytes
#       mbit: Megabits
#       kbit: Kilobits
#  To get the byte figure from bits, divide the number by 8 bit
#
# MODIFY THESE IF NEEDED
TC=/sbin/tc
IF1=eth1		    # Interface
IF2=eth2		    # Interface 
RTT=50				# as number of milliseconds
BW1=3mbit			# Bandwidth
BW2=10mbit			# Bandwidth
LOSS1=0%			# Packet loss
LOSS2=1%			# Packet loss

# DONT MODIFY THESE, THESE ARE CALCULATED FROM ABOVE
let delayNumber=$RTT/2
DELAY=$delayNumber"ms"

# COMBINATIONS
# BANDWITDH: 3Mbps, 10Mbps
# LOSS: 0%, 1%

# note that buffer param is mandatory
# it should be at least BW / CONFIG_HZ in bytes
# CONFIG_HZ is 250, but can be looked up with:
#		egrep '^CONFIG_HZ_[0-9]+' /boot/config-`uname -r`
# SO for 10Mbps BW, buffer = 10,000,000 / 250 / 8 = 5000

# limit param is the number of bytes that can sit in queue before
# tail drop policy kicks in and packets start geting dropped
# paper used buffers fo 13kB, 30kB, 60kB

# SAMPLE COMMAND
# sudo tc qdisc add dev eth0 root netem delay 200ms 40ms 25% loss 15.3% 25% duplicate 1% corrupt 0.1% reorder 5% 50%


# takes bandwidth as first arg and loss as 2nd arg
start() {

	echo "Starting with Bandwidth=$1, Loss=$2, RTT=$RTT ms: "

    $TC qdisc add dev $IF1 root handle 1: tbf rate $1 buffer 5000 limit 60000
    $TC qdisc add dev $IF1 parent 1:1 handle 10: netem delay $DELAY loss $2

    $TC qdisc add dev $IF2 root handle 1: tbf rate $1 buffer 5000 limit 60000
    $TC qdisc add dev $IF2 parent 1:1 handle 10: netem delay $DELAY loss $2

    echo "done"
}

stop() {

    $TC qdisc del dev $IF1 root
    $TC qdisc del dev $IF2 root

}

show() {

	echo "$IF1:"
    $TC -s qdisc ls dev $IF1
    echo ""
    echo ""
    echo "$IF2:"
    $TC -s qdisc ls dev $IF2
    echo ""

}

case "$1" in

  start)

    start $2"mbit" $3"%"
    ;;

  startm)

    start $2 $3
    ;;

  start1)

    start $BW1 $LOSS1
    ;;

   start2)

    start $BW1 $LOSS2
    ;;

   start3)

    start $BW2 $LOSS1
    ;;

   start4)

    start $BW2 $LOSS2
    ;;

  limit)

	start 250kbit 0%
	;;

  stop)

    echo -n "Stopping bandwidth shaping: "
    stop
    echo "done"
    ;;

  show)
    	    	    
    echo "Bandwidth shaping status for $IF1:"
    show
    echo ""
    ;;

  *)

    pwd=$(pwd)
    echo "Arguments:"
    echo ""
    echo "    start {Bandwidth in mbit} {Loss in %}   (give numbers only)"
    echo "    startm {Bandwidth} {Loss}    (you must specify units) "
    echo "    start1   :   Bandwidth=$BW1, Loss=$LOSS1"
    echo "    start2   :   Bandwidth=$BW1, Loss=$LOSS2"
    echo "    start3   :   Bandwidth=$BW2, Loss=$LOSS1"
    echo "    start4   :   Bandwidth=$BW2, Loss=$LOSS2"
    echo "    stop"
    echo "    show"
    echo ""
    echo "YOU MUST STOP BEFORE STARTING A DIFFERENT SETTING"
    echo ""
    echo "CONFIGURATION OPTIONS:"
    echo 
"TC=/sbin/tc
IF1=eth1		# Interface1
IF2=eth2		# Interface2 
RTT=50			# as number of milliseconds
BW1=3mbit		# Bandwidth on1
BW2=10mbit		# Bandwidth2
LOSS1=0%		# Packet loss
LOSS2=1%		# Packet loss"
	echo ""
	echo "Im still trying to work out how to translate packetloss and"
	echo "and bandwitdh into the one-way outbound packetloss and"
	echo "bandwidtch configurable with tc qdisc"
	echo ""
    ;;

esac

exit 0

