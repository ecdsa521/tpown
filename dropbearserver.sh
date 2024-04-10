#!/bin/sh
DAEMON=/usr/sbin/dropbearmulti
NAME=dropbear
DESC="SSH server"
ARGS="dropbear -R"

test -f $DAEMON || exit 0

set -e

case "$1" in
    start)
        echo -n "starting $DESC: $NAME... "
	test -d /etc/dropbear || mkdir /etc/dropbear
	start-stop-daemon -S -x $DAEMON -- $ARGS
	echo "done."
	;;
    stop)
        echo -n "stopping $DESC: $NAME... "
	start-stop-daemon -K -x $DAEMON
	echo "done."
	;;
    restart)
        echo "restarting $DESC: $NAME... "
 	$0 stop
	$0 start
	echo "done."
	;;
esac
exit 0